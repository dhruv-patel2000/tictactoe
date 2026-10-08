import 'dart:math';

import 'package:tic_tac_toe/features/game/models/player_model.dart';

// Enum for game status
enum GameStatus { waiting, inProgress, completed, closed }

enum PlayerTurn { player1, player2 }

enum GameResult { player1, player2, draw, notDeclared }

// Model: Firestore-backed representation of one multiplayer match (board,
// turn, result, entry fee); read/written by game_repository and GameBloc.
class GameModel {
  // Null until the game is written to Firebase; set via setGameKey() once the
  // push() reference assigns the document id.
  String? gameKey;
  final GameStatus status;
  final Player player1;
  final Player? player2;
  final List<List<String>> board;
  final PlayerTurn currentTurn;
  final GameResult result;
  final int matrixSize;
  final int rounds;
  // Mutable (unlike the other settings above) because it advances in place
  // as rounds of the same match are played.
  int currentRound;
  // Per-round outcome history for a multi-round match (one entry appended
  // per completed round).
  final List<String> roundResult;
  final int entryFee;

  // Defaults to creation time; used by fetchAvailableGames to only match
  // lobbies opened within the matchmaking search window.
  int? timeCreated = DateTime.now().millisecondsSinceEpoch;

  GameModel(
      {required this.status,
      required this.player1,
      required this.player2,
      required this.board,
      required this.currentTurn,
      required this.result,
      required this.entryFee,
      required this.matrixSize,
      required this.rounds,
      required this.currentRound,
      required this.roundResult});

  factory GameModel.createNew({
    required Player player1,
    required int matrixSize,
    required int entryFee,
    required int rounds,
  }) {
    // Two independent coin flips: who moves first is unrelated to which mark
    // (X/O) player1 is assigned, so they're rolled separately rather than
    // derived from one shared random value.
    int currentTurn = Random().nextInt(2);
    int skinType = Random().nextInt(2);
    player1.setActiveSkinType(['X', 'O'][skinType]);
    return GameModel(
        status: GameStatus.waiting,
        player1: player1,
        player2: null,
        board: List.generate(
            matrixSize, (index) => List.generate(matrixSize, (index) => "")),
        currentTurn: [PlayerTurn.player1, PlayerTurn.player2][currentTurn],
        result: GameResult.notDeclared,
        entryFee: entryFee,
        matrixSize: matrixSize,
        rounds: rounds,
        currentRound: 0,
        roundResult: <String>[]);
  }

  factory GameModel.fromJson(Map<dynamic, dynamic> json) {
    return GameModel(
        status: GameStatus.values.byName(json['status']),
        player1: Player.fromJson(json['player1']),
        player2:
            json['player2'] != null ? Player.fromJson(json['player2']) : null,
        board: (json['board'] as List<dynamic>)
            .map((row) => List<String>.from(row))
            .toList(),
        currentTurn: PlayerTurn.values.byName(json['current_turn']),
        result: GameResult.values.byName(json['result']),
        entryFee: json['entry_fee'],
        matrixSize: json['matrix_size'],
        roundResult: json['round_result'] ?? <String>[],
        rounds: json['rounds'],
        currentRound: json['current_round'])
      ..setGameKey(json['game_key']);
  }

  ///We will add the document key of the firebase to the current game to this game key element
  void setGameKey(String key) {
    gameKey = key;
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'player1': player1.toJson(),
      // Always null here: toJson() only runs on lobby creation (see
      // GameRepository.createGame), before an opponent exists. The joining
      // player2 is written later via a separate targeted update
      // (GameRepository._joinGame), not by re-serializing the whole model.
      'player2': null,
      'board': board.map((row) => row).toList(),
      'current_turn': currentTurn.name,
      'matrix_size': matrixSize,
      'rounds': rounds,
      'entry_fee': entryFee,
      'result': result.name,
      'time_created': timeCreated,
      'game_key': gameKey,
      'round_result': roundResult,
      'current_round': currentRound
    };
  }

  @override
  String toString() {
    return 'Game(status: $status, player1: $player1, player2: $player2, board: $board, currentTurn: $currentTurn, result: $result)';
  }
}
