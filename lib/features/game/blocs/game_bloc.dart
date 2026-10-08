// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc_concurrency/bloc_concurrency.dart' as bloc_transformer;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/extensions/game_board_extension.dart';
import 'package:tic_tac_toe/features/game/logic/game.dart';
import 'package:tic_tac_toe/features/game/models/game_position_model.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';

// Events consumed by GameBloc to drive a single round of play.
abstract class GameEvent {}

class Move extends GameEvent {
  final int row;
  final int column;

  Move({
    required this.row,
    required this.column,
  });
}

class BoardReplaceEvent extends GameEvent {
  final List<List<GamePosition>> board;

  BoardReplaceEvent({required this.board});
}

class NextRoundEvent extends GameEvent {
  final int round;
  NextRoundEvent({
    required this.round,
  });
}

/// Which diagonal completed a win, so the winning-line overlay can be drawn for
/// diagonal wins too (rows/columns are described by [GameOverEvent.gameOverRow]
/// / [GameOverEvent.gameOverColumn]). `main` is top-left → bottom-right, `anti`
/// is top-right → bottom-left.
enum WinDiagonal { main, anti }

class GameOverEvent extends GameEvent {
  final Player winner;
  final int? gameOverRow;
  final int? gameOverColumn;
  final WinDiagonal? diagonal;
  GameOverEvent({
    required this.winner,
    required this.gameOverRow,
    required this.gameOverColumn,
    this.diagonal,
  });
}

class GameDrawEvent extends GameEvent {}

// States emitted by GameBloc; the board UI rebuilds from these to reflect
// moves, round transitions, and win/draw outcomes.
class GameState {
  final Game game;
  GameState(this.game);
}

class PlayerMoveState extends GameState {
  final int row;
  final int column;
  final Player player;
  PlayerMoveState(
    super.game, {
    required this.row,
    required this.column,
    required this.player,
  });
}

class GameOverState extends GameState {
  final Player winner;
  final int? gameOverRow;
  final int? gameOverColumn;
  final WinDiagonal? diagonal;
  GameOverState(super.game, this.winner, this.gameOverRow, this.gameOverColumn,
      {this.diagonal});
}

class NextRoundState extends GameState {
  final int round;
  NextRoundState(super.game, this.round);
}

class GameDrawState extends GameState {
  GameDrawState(
    super.game,
  );
}

// Bloc: owns the live game/board state for one match, applies moves, and
// settles rounds on win/draw (both local and remote-echoed via Firebase).
class GameBloc extends Bloc<GameEvent, GameState> {
  /// True once the current round has been settled by a win or a draw.
  ///
  /// A device can learn the same result twice: once locally from
  /// [Game.checkWin] and again from the Firebase `result` echo of its own
  /// write. The state type can't be used to detect that — a [BoardReplaceEvent]
  /// (the echo of the winning move itself) lands in between and resets the
  /// state to a plain [GameState], so the second result would be treated as
  /// fresh and stack a duplicate end-of-game dialog. Cleared by
  /// [NextRoundEvent] so every round of a multi-round match settles once.
  bool _roundSettled = false;

  GameBloc(super.game) {
    on<BoardReplaceEvent>((event, emit) async {
      final Game game = state.game;
      game.board = event.board;
      emit(GameState(game));
    });
    on<GameOverEvent>((event, emit) async {
      if (_roundSettled) return;
      _roundSettled = true;
      emit(GameOverState(
          state.game, event.winner, event.gameOverRow, event.gameOverColumn,
          diagonal: event.diagonal));
    });
    on<GameDrawEvent>((event, emit) async {
      if (_roundSettled) return;
      _roundSettled = true;
      emit(GameDrawState(state.game));
    });
    on<Move>(
      (event, emit) async {
        if (_roundSettled) return;

        final List<List<GamePosition>> board = state.game.board;

        // move() only fails (returns false) for an already-occupied cell; the
        // UI's restrictedMoves guard is expected to keep that from happening,
        // so `moved` here mainly gates the win check below, not the state
        // emission or turn advance further down.
        final bool moved = board.move(
            x: event.row, y: event.column, player: state.game.currentPlayer!);

        bool gameEnded = false;
        if (moved) {
          state.game.board = board;
          gameEnded = state.game.checkWin();
        }

        ///Here created separately because we want to set current player to state and the change new state with next player
        final PlayerMoveState moveState = PlayerMoveState(state.game,
            row: event.row,
            column: event.column,
            player: state.game.currentPlayer!);
        // A game-ending move must not advance the turn: for multiplayer this
        // writes `current_turn` to the DB, which would let the opponent take
        // another move before the game-over/draw settlement lands.
        if (!gameEnded) {
          state.game.setNextPlayer();
        } else {
          // setNextPlayer() (skipped above) is what normally cancels the
          // in-flight turn timer. Without this, the old timer keeps counting
          // down unattended and can hit zero during the post-game-over delay,
          // firing a bogus timeout GameOverEvent that overwrites the real
          // result — on the winner's own device, since currentPlayer/selfPlayerId
          // still match there.
          state.game.countdown?.reset();
        }
        emit(moveState);
      },
      transformer: bloc_transformer
          .sequential(), // This bloc transformer will make sure that the event is processed sequentially. Please do not remove it. We will prevent any unnecessary moves on the board.
    );

    on<NextRoundEvent>((NextRoundEvent event, Emitter<GameState> emit) async {
      await Future.delayed(Duration(microseconds: 100));
      // Clear the board locally for the new round. We can't rely solely on the
      // DB `board` echo to reset it (its arrival isn't ordered relative to this
      // round-change event), so reset here to guarantee the new round starts
      // clean and the previous round's last move never lingers.
      _roundSettled = false;
      state.game.setNextRound(event.round);
      emit(NextRoundState(state.game, event.round));
    });
  }
}
