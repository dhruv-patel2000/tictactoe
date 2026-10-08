import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/core/constants/settings.dart';
import 'package:tic_tac_toe/features/game/models/game_model.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';
import 'package:tic_tac_toe/features/history/models/history_model.dart';
import 'package:tic_tac_toe/commons/repositories/coin_repository.dart';
import 'package:tic_tac_toe/features/history/repositories/history_repository.dart';
import 'package:tic_tac_toe/features/leaderboard/repositories/leaderboard_ranking.dart';

/// Thrown by [GameRepository.connectGame] when the player can't cover the
/// entry fee. The bloc turns this into a user-facing "not enough coins"
/// message instead of letting the player enter a game they can't pay for.
class InsufficientCoinsException implements Exception {
  final int required;
  const InsufficientCoinsException(this.required);
}

/// Multiplayer game lobby, board, and settlement (coin payout + stats +
/// history) data access.
class GameRepository {
  GameRepository(this._database, this._coins, this._history);

  final FirebaseDatabase _database;
  final CoinRepository _coins;
  final HistoryRepository _history;

  DatabaseReference get _games => _database.ref().child('games');

  //--------------------------------------------------
  // Lobby & Connection
  //--------------------------------------------------

  Future<({GameConnection connection, GameModel game})> connectGame({
    required Player player,
    required int matrixSize,
    required int entryFee,
    required int rounds,
  }) async {
    // Escrow this player's stake before touching the lobby. Aborting here when
    // the balance can't cover the fee means we never create or join a game we
    // can't pay for.
    final bool funded = await _coins.debitCoins(player.playerId, entryFee);
    if (!funded) {
      throw InsufficientCoinsException(entryFee);
    }

    try {
      GameModel? game = await fetchAvailableGames(
          entryFee: entryFee,
          rounds: rounds,
          matrixSize: matrixSize,
          excludingPlayerId: player.playerId);

      if (game == null) {
        GameModel newGame = GameModel.createNew(
            player1: player,
            matrixSize: matrixSize,
            entryFee: entryFee,
            rounds: rounds);
        await createGame(newGame);
        return (game: newGame, connection: GameConnection.created);
      } else {
        player
            .setActiveSkinType(game.player1.activeSkinType == 'X' ? 'O' : 'X');
        await _joinGame(game.gameKey!, player);
        return (game: game, connection: GameConnection.joined);
      }
    } catch (e) {
      // Creating/joining failed after we debited — refund the stake so coins
      // are never swallowed by an error mid-connect.
      await _coins.creditCoins(player.playerId, entryFee);
      rethrow;
    }
  }

  Future<void> _joinGame(String gameKey, Player player) async {
    ///Setting player2 and the status together (single update) so the game
    ///flips from waiting to inProgress the moment the opponent joins.
    await _games.child(gameKey).update({
      'player2': player.toJson(),
      'status': GameStatus.inProgress.name,
    });
  }

  /// Closes a waiting game so nobody can join it after the host leaves — called
  /// both when the host's connection timer expires and when the host backs out
  /// of the waiting screen (otherwise the game lingers as a joinable "ghost").
  ///
  /// The `waiting -> closed` flip is a transaction so only the first caller wins
  /// it; that caller is the only one that refunds the escrowed stake, so the
  /// timer and the back-out cleanup can't double-refund. Returns `true` only for
  /// that winning caller. Aborts (returns `false`) when the game is no longer
  /// waiting — i.e. an opponent already joined (status is `inProgress`, set
  /// atomically with `player2` in [_joinGame]) or it was already closed.
  Future<bool> closeGame(String gameKey) async {
    final txn =
        await _games.child(gameKey).child('status').runTransaction((current) {
      if (current != GameStatus.waiting.name) return Transaction.abort();
      return Transaction.success(GameStatus.closed.name);
    });
    if (!txn.committed) return false;

    // We won the close and no opponent joined: release the host's escrowed stake.
    final dynamic data = (await _games.child(gameKey).get()).value;
    final int entryFee = (data?['entry_fee'] as int?) ?? 0;
    final String? hostId = data?['player1']?['playerId'] as String?;
    if (hostId != null) {
      await _coins.creditCoins(hostId, entryFee);
    }
    return true;
  }

  Future<void> listenOpponentJoin(
      String gameKey, Function(Player opponent) onOpponentJoined) async {
    _games.child(gameKey).onChildAdded.listen((DatabaseEvent event) {
      final String? changedKey = event.snapshot.key;
      final dynamic newValue = event.snapshot.value;

      if (changedKey == 'player2') {
        onOpponentJoined.call(Player.fromJson(newValue));
      }
    });
  }

  Future<void> createGame(GameModel model) async {
    final DatabaseReference gameReference = _games.push();
    model.setGameKey(gameReference.key!);
    await gameReference.set(model.toJson());
  }

  /// Finds a waiting game to join. Only games matching the player's chosen
  /// [entryFee] (price), [rounds] (level) and [matrixSize] (board size) are
  /// eligible — players are never paired into a game with different settings.
  Future<GameModel?> fetchAvailableGames({
    required int entryFee,
    required int rounds,
    required int matrixSize,
    required String excludingPlayerId,
  }) async {
    // Upper bound: only consider lobbies that already existed when this
    // lookup started.
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    // Lower bound: how far back to search for a still-open lobby, so a
    // lobby abandoned long ago isn't offered as joinable. Deliberately much
    // wider than the ~60s countdown shown on the connection screen (`* 100`):
    // that UI timer is how long *this* client waits before giving up, not how
    // long a lobby stays matchable by other clients searching later.
    final int lookupTime = DateTime.now()
        .subtract(Duration(
            seconds: AppSettings.multiplayerConnectionSearchTime * 100))
        .millisecondsSinceEpoch;

    final Query query = _database
        .ref()
        .child('games')
        .orderByChild('time_created')
        .startAfter(lookupTime, key: 'time_created')
        .endBefore(currentTime);

    final DataSnapshot result = (await query.once()).snapshot;
    final List games = result.children.toList();

    games
      ..removeWhere(
          (element) => element.value['status'] != GameStatus.waiting.name)
      ..removeWhere((element) => element.value['player2'] != null)
      ..removeWhere((element) =>
          element.value['player1']['playerId'] == excludingPlayerId)
      // Only join a game with the same price, level (rounds) and board size.
      ..removeWhere((element) => element.value['entry_fee'] != entryFee)
      ..removeWhere((element) => element.value['rounds'] != rounds)
      ..removeWhere((element) => element.value['matrix_size'] != matrixSize);

    if (games.isEmpty) {
      return null;
    }

    return GameModel.fromJson(games.first.value);
  }

  //--------------------------------------------------
  // Game State
  //--------------------------------------------------

  Future<GameModel> getGame(String gameKey) async {
    return GameModel.fromJson(
        (await _games.child(gameKey).once()).snapshot.value as dynamic);
  }

  Future<void> updateMove(
      String gameKey, int row, int column, Player player) async {
    await _games
        .child(gameKey)
        .child('board')
        .child('$row')
        .child('$column')
        .set(player.toJson());
  }

  StreamSubscription<DatabaseEvent> listenGame(
      String gameKey, Function(DatabaseEvent game) onGameUpdate) {
    return _games.child(gameKey).onChildChanged.listen((DatabaseEvent event) {
      onGameUpdate.call(event);
    });
  }

  Future<void> nextPlayer(String gameKey, String nextPlayer) async {
    await _games.child(gameKey).update({'current_turn': nextPlayer});
  }

  //--------------------------------------------------
  // Result & Settlement
  //--------------------------------------------------

  /// Declares the final result of [gameKey] and pays out the pot.
  ///
  /// Both clients detect game-over, so the result flip is done as a transaction
  /// on the `result` node: whichever client moves it off `'notDeclared'` first
  /// wins the claim and is the only one that runs the payout below. The loser
  /// of that race returns early, guaranteeing the pot is paid exactly once.
  ///
  /// [result] carries `player`, which is one of [GameResult.player1],
  /// [GameResult.player2] (a win or an opponent forfeit) or [GameResult.draw].
  Future<void> setGameResult(
      String gameKey, Map<String, dynamic> result) async {
    final claim =
        await _games.child(gameKey).child('result').runTransaction((current) {
      // Only the first writer past 'notDeclared' wins the claim.
      if (current != 'notDeclared') return Transaction.abort();
      return Transaction.success(result);
    });

    // Someone else already settled this game; nothing more to do.
    if (!claim.committed) return;

    // ── Payout ──────────────────────────────────────────────────────────────
    // Pot = both stakes. Winner takes all (net +fee); a draw returns each
    // player's own stake (net 0).
    final dynamic data = (await _games.child(gameKey).get()).value;
    final int entryFee = (data?['entry_fee'] as int?) ?? 0;
    final String? p1 = data?['player1']?['playerId'] as String?;
    final String? p2 = data?['player2']?['playerId'] as String?;

    if (result['player'] == GameResult.draw.name) {
      if (p1 != null) {
        await _coins.creditCoins(p1, entryFee);
        await _recordStats(p1,
            won: false, scoreDelta: AppSettings.scoreForDraw);
        // A draw returns the stake, so the net coin change is 0.
        await _history.recordHistory(p1, HistoryStatus.tie, 0);
      }
      if (p2 != null) {
        await _coins.creditCoins(p2, entryFee);
        await _recordStats(p2,
            won: false, scoreDelta: AppSettings.scoreForDraw);
        await _history.recordHistory(p2, HistoryStatus.tie, 0);
      }
    } else {
      final bool player1Won = result['player'] == GameResult.player1.name;
      final String? winnerId = player1Won ? p1 : p2;
      final String? loserId = player1Won ? p2 : p1;
      if (winnerId != null) {
        await _coins.creditCoins(winnerId, entryFee * 2);
        await _recordStats(winnerId,
            won: true, scoreDelta: AppSettings.scoreForWin);
        // Net coin change is +entryFee (staked entryFee, received 2x).
        await _history.recordHistory(winnerId, HistoryStatus.won, entryFee);
      }
      if (loserId != null) {
        await _recordStats(loserId,
            won: false, scoreDelta: AppSettings.scoreForLoss);
        await _history.recordHistory(loserId, HistoryStatus.lost, -entryFee);
      }
    }
  }

  Future<int> updateRound(String gameKey, int boardSize) async {
    final DataSnapshot snapshot = await _games.child(gameKey).get();
    final int nextRound =
        ((snapshot.value as dynamic)['current_round'] as int) + 1;
    final player = (snapshot.value as dynamic)['current_turn'];
    final List<List<String>> newBoard = List.generate(
        boardSize, (index) => List.generate(boardSize, (index) => ""));

    await _games.child(gameKey).update({
      'current_round': nextRound,
      'board': newBoard,
      'current_turn': player == 'player1' ? 'player2' : 'player1'
    });
    return nextRound;
  }

  /// Records a finished match on [uid]'s profile: `matchplayed` always +1,
  /// `matchwon` +1 when [won], and `score` += [scoreDelta] with its `rankKey`
  /// rebuilt so the leaderboard stays ordered. Done as a transaction so it can't
  /// clobber a concurrent coin/score write. Settlement runs on a single client
  /// (the result claimer), which writes both players' stats — the same
  /// cross-user write pattern already used by the coin payout above.
  Future<void> _recordStats(String uid,
      {required bool won, required int scoreDelta}) async {
    await _database.ref().child('users').child(uid).runTransaction((current) {
      if (current == null) return Transaction.abort();
      final Map<String, dynamic> user =
          Map<String, dynamic>.from(current as Map);

      final int matchPlayed = (user['matchplayed'] as int?) ?? 0;
      final int matchWon = (user['matchwon'] as int?) ?? 0;
      final int score = (user['score'] as int?) ?? 0;
      final int createdAt = (user['createdAt'] as int?) ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final int newScore = score + scoreDelta;

      user['matchplayed'] = matchPlayed + 1;
      if (won) user['matchwon'] = matchWon + 1;
      user['score'] = newScore;
      user['createdAt'] = createdAt;
      user['rankKey'] =
          rankKeyFor(score: newScore, createdAtSeconds: createdAt);
      return Transaction.success(user);
    });
  }
}
