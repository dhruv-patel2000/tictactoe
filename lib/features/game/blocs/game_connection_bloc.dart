// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/features/game/models/game_model.dart';
import 'package:tic_tac_toe/features/game/models/game_round_model.dart';
import 'package:tic_tac_toe/features/game/models/matrix_size_model.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';

// Events consumed by GameConnectionBloc while creating/joining a multiplayer
// match and waiting for an opponent.
class GameJoinEvent {}

class ConnectGame extends GameJoinEvent {
  final Player player1;
  final MatrixSize size;
  final int fee;
  final GameRound round;
  ConnectGame({
    required this.player1,
    required this.size,
    required this.fee,
    required this.round,
  });
}

class ListenOpponentJoin extends GameJoinEvent {
  final String gameId;

  ListenOpponentJoin(this.gameId);
}

/// Dispatched when the host's connection timer expires so the waiting game is
/// closed (unless an opponent already joined).
class CloseGame extends GameJoinEvent {
  final String gameId;

  CloseGame(this.gameId);
}

// States emitted by GameConnectionBloc; the matchmaking screen renders these
// while a game is created, waits for an opponent, or fails to connect.
abstract class GameConnectionState {}

class GameConnectionInitial extends GameConnectionState {}

class GameConnectionInProgress extends GameConnectionState {}

/// Emitted once a fresh game has been created and we are waiting for an
/// opponent. Carries the game key so the screen can close it on timeout.
class GameConnectionWaiting extends GameConnectionState {
  final String gameKey;
  GameConnectionWaiting({required this.gameKey});
}

class GameConnectionSuccess extends GameConnectionState {
  final String gameKey;
  GameConnectionSuccess({
    required this.gameKey,
  });
}

/// Emitted when the game was closed because no opponent joined in time.
class GameConnectionClosed extends GameConnectionState {}

/// Emitted when the player can't cover the entry fee, so no game was created
/// or joined and nothing was debited.
class GameConnectionInsufficientCoins extends GameConnectionState {
  final int required;
  GameConnectionInsufficientCoins(this.required);
}

class GameConnectionFailure extends GameConnectionState {}

// Bloc: creates/joins a multiplayer game via Firebase, deducts the entry fee,
// and tracks matchmaking status until an opponent joins or the wait times out.
class GameConnectionBloc extends Bloc<GameJoinEvent, GameConnectionState> {
  GameConnectionBloc() : super(GameConnectionInitial()) {
    on<ConnectGame>((event, emit) async {
      try {
        emit(GameConnectionInProgress());
        final ({GameConnection connection, GameModel game}) result =
            await DatabaseService.instance.connectGame(
                player: event.player1,
                matrixSize: event.size.size,
                entryFee: event.fee,
                rounds: event.round.digit);
        if (result.connection == GameConnection.created) {
          emit(GameConnectionWaiting(gameKey: result.game.gameKey!));
          // Brief pause so the "waiting for opponent" UI has a moment on screen
          // before the opponent-listener event fires.
          await Future.delayed(Duration(seconds: 1));
          if (isClosed) return;
          add(ListenOpponentJoin(result.game.gameKey!));
        } else {
          emit(GameConnectionSuccess(gameKey: result.game.gameKey!));
        }
      } on InsufficientCoinsException catch (e) {
        emit(GameConnectionInsufficientCoins(e.required));
      } catch (e) {
        emit(GameConnectionFailure());
        rethrow;
      }
    });

    on<ListenOpponentJoin>((event, emit) async {
      /*Here we are using completer because if we do not use it the event will become
       complete when the async call is done and the bloc will wait for the listener
        response so we are creating empty future to indicate the future is still active till we do not get join request*/
      final completer = Completer<void>();

      await DatabaseService.instance.listenOpponentJoin(
        event.gameId,
        (opponent) {
          Future.delayed(
            Duration.zero,
            () {
              emit(GameConnectionSuccess(gameKey: event.gameId));
              completer.complete();
            },
          );
        },
      );
      await completer.future;
    });

    on<CloseGame>((event, emit) async {
      ///If an opponent joined while the timer was expiring the join wins and we
      ///proceed into the game instead of closing it.
      final bool closed =
          await DatabaseService.instance.closeGame(event.gameId);
      if (closed) {
        emit(GameConnectionClosed());
      } else {
        emit(GameConnectionSuccess(gameKey: event.gameId));
      }
    });
  }
}
