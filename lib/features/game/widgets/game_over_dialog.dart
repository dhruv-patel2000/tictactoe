import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/borderd_container.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/features/game/logic/game.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';
import 'package:tic_tac_toe/features/game/widgets/dashed_avatar_widget.dart';

// Shown when a game (final round) ends with a winner; offers restart for
// local modes or returns to home for multiplayer.
class GameOverDialog extends StatelessWidget {
  final Game game;
  final Player winner;
  final int?
      entryFee; // stake per player; winner's payout shown as double this, loser's shown as their loss
  final bool isMultiplayer;

  const GameOverDialog({
    super.key,
    required this.winner,
    this.entryFee,
    required this.isMultiplayer,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialogBox(
      title: context.tr('gameOver'),
      hideCloseButton: true,
      buttons: [
        DialogButton(
          title: isMultiplayer ? context.tr('ok') : context.tr('cancel'),
          onTap: () {
            if (isMultiplayer) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.homeScreen,
                (route) => false,
              );
            } else {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
        if (!isMultiplayer)
          DialogButton(
            color: context.color.onSurface,
            title: context.tr('restart'),
            textColor: context.color.surface,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.mazeScreen,
                arguments: game..reset(),
              );
            },
          ),
      ],
      child: Column(
        spacing: 16.r(context),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Multiplayer is written from the local player's point of view:
          // their own avatar and name sit above their own result, so a loser
          // is never shown the winner's face over their "You lost:" line. The
          // local modes have no such result line, so they keep announcing the
          // winner.
          DashedAvatarWidget(
            image:
                isMultiplayer ? game.self.playerProfile : winner.playerProfile,
          ),
          CustomText(
            isMultiplayer ? game.self.name : winner.name,
            fontSize: context.font.medium,
            fontWeight: FontWeight.w600,
          ),
          if (isMultiplayer)
            FittedBox(
              fit: BoxFit.none,
              child: BorderContainer(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.r(context),
                  vertical: 6.r(context),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6.r(context),
                  children: [
                    CustomText(
                      winner.isYou
                          ? context.tr('winningPrice')
                          : context.tr('youLost'),
                      fontSize: context.font.normal,
                    ),
                    CustomText(
                      winner.isYou
                          ? (entryFee! * 2).toString()
                          : entryFee.toString(),
                      fontSize: context.font.large,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
