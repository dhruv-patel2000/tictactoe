import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/features/game/logic/game.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/features/game/blocs/game_bloc.dart';
import 'package:tic_tac_toe/features/game/models/game_model.dart';
import 'package:tic_tac_toe/features/game/models/game_position_model.dart';
import 'package:tic_tac_toe/features/game/models/game_setting_model.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';

/// Online game mode: moves and turn order are driven by a Firebase Realtime
/// Database game record rather than local state, so both devices stay in
/// sync by listening to the same node.
class MultiplayerGame extends Game {
  @override
  bool restrictedMoves = true;

  MultiplayerGame({required MultiplayerGameSetting settings})
      : super(settings: settings);

  @override
  MultiplayerGameSetting get settings =>
      super.settings as MultiplayerGameSetting;

  StreamSubscription<DatabaseEvent>?
      subscription; // listens to the Firebase game node; cancelled in [onDispose]

  @override
  String get note => "Note: Winning Amount Will be 2X of Entry Amount";
  @override
  void onGameStart() {
    super.onGameStart();
    showNote = true;

    selfPlayerId = settings.gameModel.player1.playerId ==
            FirebaseAuth.instance.currentUser?.uid
        ? settings.gameModel.player1.playerId
        : settings.gameModel.player2?.playerId;

    player1 = settings.gameModel.player1;
    player2 = settings.gameModel.player2;
    currentPlayer = settings.gameModel.currentTurn == PlayerTurn.player1
        ? settings.gameModel.player1
        : settings.gameModel.player2;

    subscription = DatabaseService.instance
        .listenGame(settings.gameModel.gameKey!, (DatabaseEvent event) async {
      if (event.snapshot.key == 'board') {
        _updateBoard(getContext()!, event);
      }
      if (event.snapshot.key == 'current_turn') {
        _updateCurrentPlayer(getContext()!, event);
      }
      if (event.snapshot.key == 'result') {
        // Fires on both devices, including the one that wrote the result after
        // settling locally. GameBloc drops a second GameOverEvent/GameDrawEvent
        // for an already-settled round, so forwarding it unconditionally can't
        // stack a duplicate end-of-game dialog.
        _updateResult(getContext()!, event);
      }
      if (event.snapshot.key == 'current_round') {
        addEvent(NextRoundEvent(round: event.snapshot.value as int));
      }
    });
  }

  void _updateBoard(BuildContext context, DatabaseEvent event) {
    final List<List<GamePosition>> newBoard = List.generate(
      settings.boardSize,
      (row) => List.generate(
        settings.boardSize,
        (column) {
          final data = (event.snapshot.value as dynamic)[row]
              [column]; // raw DB entry for this cell, or null if unplayed

          if (data is! Map) {
            return GamePosition();
          }
          return GamePosition(
              playerId: data['playerId'],
              skin: data['active_skin_type'] == 'O'
                  ? data['skinO']
                  : data['skinX']);
        },
      ),
    );
    context.read<GameBloc>().add(BoardReplaceEvent(board: newBoard));
  }

  @override
  FutureOr<void> onUpdate(int row, int column, Player player) async {
    DatabaseService.instance
        .updateMove(settings.gameModel.gameKey!, row, column, player);
  }

  @override
  Future<void> onGameOver(Player winner, int? winRow, int? winColumn,
      {WinDiagonal? diagonal}) async {
    // currentRound is 0-based, rounds is a count, so currentRound == rounds - 1
    // is the final round; anything before that just moves on to the next round.
    if (settings.gameModel.currentRound < (settings.gameModel.rounds - 1)) {
      await DatabaseService.instance
          .updateRound(settings.gameModel.gameKey!, settings.boardSize);
    } else {
      await DatabaseService.instance
          .setGameResult(settings.gameModel.gameKey!, {
        'player': winner.playerId == player1?.playerId
            ? GameResult.player1.name
            : GameResult.player2.name,
        'winRow': winRow,
        'winColumn': winColumn,
        // So the opponent's device can draw the winning line for diagonal wins.
        'winDiagonal': diagonal?.name,
      });
    }
  }

  @override
  Future<void> onGameDraw() async {
    // Mirror onGameOver's round handling: a draw on an earlier round just
    // advances to the next one; a draw on the final round settles the match
    // (setGameResult returns each player's own stake).
    if (settings.gameModel.currentRound < (settings.gameModel.rounds - 1)) {
      await DatabaseService.instance
          .updateRound(settings.gameModel.gameKey!, settings.boardSize);
    } else {
      await DatabaseService.instance
          .setGameResult(settings.gameModel.gameKey!, {
        'player': GameResult.draw.name,
      });
    }
  }

  @override
  void onDispose() {
    subscription?.cancel();
    super.onDispose();
  }

  @override
  void setNextPlayer() {
    final String nextPlayer =
        currentPlayer?.playerId == player1?.playerId ? 'player2' : 'player1';
    //No async call here.
    DatabaseService.instance
        .nextPlayer(settings.gameModel.gameKey!, nextPlayer);

    ///This super call must always be below the database call
    super.setNextPlayer();
  }

  void _updateCurrentPlayer(BuildContext context, DatabaseEvent event) {
    countdown?.reset();
    countdown?.start();
    currentPlayer = event.snapshot.value == 'player1' ? player1 : player2;
  }

  void _updateResult(BuildContext context, DatabaseEvent event) {
    final Map result = event.snapshot.value
        as Map; // settled result payload written by [onGameOver]/[onGameDraw]

    // A draw has no winner — settlement already refunded both stakes. Route it
    // through GameDrawEvent (not GameOverEvent, which would falsely crown
    // player2) so this device shows the draw dialog.
    if (result['player'] == GameResult.draw.name) {
      addEvent(GameDrawEvent());
      return;
    }

    final String? winDiagonal = result['winDiagonal'] as String?;
    addEvent(GameOverEvent(
        gameOverRow: result['winRow'],
        gameOverColumn: result['winColumn'],
        diagonal:
            winDiagonal != null ? WinDiagonal.values.byName(winDiagonal) : null,
        winner:
            result['player'] == GameResult.player1.name ? player1! : player2!));
  }
}
