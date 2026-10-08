// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tic_tac_toe/utils/countdown.dart';
import 'package:tic_tac_toe/utils/extensions/game_board_extension.dart';
import 'package:tic_tac_toe/utils/extensions/list_extension.dart';
import 'package:tic_tac_toe/features/game/blocs/game_bloc.dart';
import 'package:tic_tac_toe/features/game/models/game_position_model.dart';
import 'package:tic_tac_toe/features/game/models/game_setting_model.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';

/// Base game engine shared by [OfflineGame], [MultiplayerGame] and
/// [PassNPlayGame]: owns the board, turn order, win/draw detection and the
/// countdown clock, and dispatches [GameEvent]s to [GameBloc]. Subclasses
/// plug in how players are set up and how a placed move gets applied.
abstract class Game {
  Player? player1;
  Player? player2;
  Player? currentPlayer; // whose turn it is right now
  String?
      selfPlayerId; // playerId of this device's player, used to resolve [self]/[opponent]
  bool initialized =
      false; // set once onGameStart has run, so callers don't re-trigger it
  Countdown? countdown;
  bool showNote =
      false; // whether the note banner should be shown (multiplayer wagered games only)

  String note = "";

  Player get opponent {
    final Player? found = selfPlayerId == player1?.playerId ? player2 : player1;
    if (found == null) {
      throw StateError(
          'Game.opponent read before player1/player2 were assigned');
    }
    return found;
  }

  /// The player sitting at this device — the mirror of [opponent]. Only
  /// meaningful where [selfPlayerId] identifies one side (multiplayer, and
  /// offline where it is player1); pass-n-play has both players on one device.
  Player get self {
    final Player? found = selfPlayerId == player1?.playerId ? player1 : player2;
    if (found == null) {
      throw StateError('Game.self read before player1/player2 were assigned');
    }
    return found;
  }

  bool get restrictedMoves;

  covariant GameSettings settings;
  BuildContext?
      _context; // set via [setContext]; used to dispatch [GameEvent]s to [GameBloc]

  void setContext(BuildContext context) {
    _context = context;
  }

  void reset() {
    _generateBoard();
    currentPlayer = null;
    player1 = null;
    player2 = null;
    selfPlayerId = null;
    initialized = false;
  }

  void setNextRound(int round) {
    _generateBoard();
    (settings as MultiplayerGameSetting).gameModel.currentRound = round;
  }

  List<List<GamePosition>> board =
      []; // authoritative boardSize x boardSize grid of moves so far

  List<List<GamePosition>> columnOrientedBoard() {
    return List.generate(
        board.length, (column) => board.map((e) => e[column]).toList());
  }

  bool isBoardFull() {
    return board.expand((list) => list).toList().every(
          (element) => !element.isBlank,
        );
  }

  /// Returns `true` when this check ended the game (win or draw) and has
  /// already dispatched the corresponding [GameOverEvent]/[GameDrawEvent].
  /// The caller must not advance to the next player when this returns `true`
  /// — doing so before the game-over/draw settlement lands would let an
  /// opponent (multiplayer) take another move on what the DB still shows as
  /// their turn.
  bool checkWin() {
    if (currentPlayer == null) return false;
    int?
        rowNumber; // index of the winning row, if the win is a row (for the win-line overlay)
    int?
        columnNumber; // index of the winning column, if the win is a column (for the win-line overlay)
    final String basePlayerId = currentPlayer!.playerId;

    final bool rowCheck = board.indexedAny((row, index) {
      final bool isWin = row.every((position) =>
          position.playerId != null && position.playerId == basePlayerId);
      if (isWin) {
        rowNumber = index;
      }
      return isWin;
    });

    final bool columnCheck = columnOrientedBoard().indexedAny((column, index) {
      final bool isWin = column.every((position) =>
          position.playerId != null && position.playerId == basePlayerId);
      if (isWin) {
        columnNumber = index;
      }
      return isWin;
    });

    final bool diagonalCheckClockWise = board.asMap().entries.every((element) {
      return (board.diagonal(element.key).playerId != null &&
          board.diagonal(element.key).playerId == basePlayerId);
    });

    final bool diagonalCheckCounterClockWise =
        board.asMap().entries.every((element) {
      return (board.diagonalFromEnd(element.key).playerId != null &&
          board.diagonalFromEnd(element.key).playerId == basePlayerId);
    });

    if (rowCheck ||
        columnCheck ||
        diagonalCheckClockWise ||
        diagonalCheckCounterClockWise) {
      addEvent(GameOverEvent(
          winner: currentPlayer!,
          gameOverColumn: columnNumber,
          gameOverRow: rowNumber,
          diagonal: diagonalCheckClockWise
              ? WinDiagonal.main
              : (diagonalCheckCounterClockWise ? WinDiagonal.anti : null)));
      return true;
    } else if (isBoardFull()) {
      addEvent(GameDrawEvent());
      return true;
    }
    return false;
  }

  Game({required this.settings}) {
    _generateBoard();
  }
  void _generateBoard() {
    final boardSize = settings.boardSize;
    board = List.generate(
      boardSize,
      (row) => List.generate(
        boardSize,
        (column) => GamePosition(),
      ),
    );
  }

  void addEvent(GameEvent event) {
    if (_context != null) {
      _context!.read<GameBloc>().add(event);
    }
  }

  BuildContext? getContext() {
    assert(_context != null, 'Please set context before calling getContext()');
    return _context;
  }

  @mustCallSuper
  void onGameStart() {
    initialized = true;
  }

  FutureOr<void> onGameOver(Player winner, int? winRow, int? winColumn,
      {WinDiagonal? diagonal}) {}

  FutureOr<void> onUpdate(int row, int column, Player player);

  FutureOr<void> setNextPlayer() {
    if (player1 != null && player2 != null) {
      currentPlayer =
          currentPlayer?.playerId == player1?.playerId ? player2 : player1;
    }

    // Every turn starts with a full clock. This is the single turn-change point
    // for the local modes (offline / pass-n-play); multiplayer also resets via
    // its DB current_turn listener, so the extra local reset here is harmless.
    countdown?.reset();
    countdown?.start();
  }

  FutureOr<void> onGameDraw() {}
  void onDispose() {}
}
