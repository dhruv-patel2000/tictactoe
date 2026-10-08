import 'dart:math';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/features/game/logic/game.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';

// Local two-player mode: both players share one device, so there's no self
// player, no AI, and no server round-trip on a move.
class PassNPlayGame extends Game {
  PassNPlayGame({required super.settings});

  @override
  void onGameStart() async {
    super.onGameStart();

    player1 = Player(
        playerId: '0',
        skinX: DatabaseService.instance.activeSkin.skinX,
        name: 'User1',
        skinO: DatabaseService.instance.activeSkin.skinO,
        activeSkinType: 'O',
        playerProfile: AppIcons.dora1);

    player2 = Player(
        playerId: '1',
        skinX: DatabaseService.instance.activeSkin.skinX,
        name: 'User2',
        skinO: DatabaseService.instance.activeSkin.skinO,
        activeSkinType: 'X',
        playerProfile: AppIcons.dora1);
    currentPlayer = [player1, player2][Random().nextInt(2)];
  }

  @override
  void onUpdate(int row, int column, Player player) async {}

  @override
  bool restrictedMoves = false;
}
