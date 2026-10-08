import 'package:tic_tac_toe/features/game/models/game_model.dart';

// Model: local game configuration (board size, entry fee) used to start a
// new match before a GameModel exists.
class GameSettings {
  final int boardSize;
  int? fee;

  GameSettings({required this.boardSize, this.fee});
}

// Model: wraps an existing multiplayer GameModel (rejoin/reconnect case) so
// its board size and fee can be read through the common GameSettings shape.
class MultiplayerGameSetting extends GameSettings {
  final GameModel gameModel;
  MultiplayerGameSetting(this.gameModel, {required super.boardSize}) {
    super.fee = gameModel.entryFee;
  }
}
