import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/borderd_container.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/features/game/logic/game.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';
import 'package:tic_tac_toe/features/game/widgets/dashed_avatar_widget.dart';

/// Shown when a multiplayer (or local) match ends in a draw. A draw returns
/// each player their own stake, so there is no winner and no net coin change.
class DrawDialog extends StatelessWidget {
  final Game game;
  final Player player1;
  final Player player2;
  final int?
      entryFee; // stake to display as "returned"; null when the match wasn't a paid multiplayer match
  final bool isMultiplayer;

  const DrawDialog({
    super.key,
    required this.game,
    required this.player1,
    required this.player2,
    required this.isMultiplayer,
    this.entryFee,
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
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
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
                Navigator.pushReplacementNamed(context, AppRoutes.mazeScreen,
                    arguments: game..reset());
              },
            ),
        ],
        child: Column(
          spacing: 16.r(context),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.sizes.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DashedAvatarWidget(
                    image: player1.playerProfile,
                    size: 73.r(context),
                  ),
                  CustomImage(AppIcons.versus),
                  DashedAvatarWidget(
                    image: player2.playerProfile,
                    size: 73.r(context),
                  ),
                ],
              ),
            ),
            Text(
              context.tr('itsADraw'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.font.medium,
              ),
            ),
            if (isMultiplayer && entryFee != null)
              FittedBox(
                fit: BoxFit.none,
                child: BorderContainer(
                    child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      context.tr('stakeReturned',
                          params: {'amount': entryFee.toString()}),
                      fontSize: context.font.medium,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                )),
              ),
          ],
        ));
  }
}
