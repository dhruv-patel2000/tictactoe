import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dotted_border/dotted_border.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/marquee.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';
import 'package:tic_tac_toe/features/game/widgets/dashed_avatar_widget.dart';

// Shown between rounds of a multi-round match; announces the round winner
// (or draw) and auto-dismisses after a short countdown.
class NextRoundDialog extends StatefulWidget {
  final Player player1;
  final Player player2;
  final int round;
  final Player?
      winner; // round winner to announce; null means the round was a tie

  const NextRoundDialog({
    super.key,
    required this.player1,
    required this.player2,
    required this.winner,
    required this.round,
  });

  @override
  State<NextRoundDialog> createState() => _NextRoundDialogState();
}

class _NextRoundDialogState extends State<NextRoundDialog> {
  Timer? timer;
  int time = 3;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      time--;
      // Countdown hits zero: auto-dismiss so the next round starts without
      // requiring a tap.
      if (time == 0) {
        Navigator.pop(context);
        timer.cancel();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialogBox(
      title: context.tr('nextRound'),
      hideCloseButton: true,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.sizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DashedAvatarWidget(
                  image: widget.player1.playerProfile,
                  size: 73.r(context),
                ),
                CustomImage(AppIcons.versus),
                DashedAvatarWidget(
                  image: widget.player2.playerProfile,
                  size: 73.r(context),
                ),
              ],
            ),
          ),
          CustomText(
            context.tr('roundNumber', params: {'round': '${widget.round + 1}'}),
            fontSize: context.font.medium,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(
            width: context.screenWidth * 0.5,
            child: MarqueeWidget(
              child: CustomText(
                widget.winner == null
                    ? context.tr('itsADraw')
                    : context.tr('playerVictory',
                        params: {'player': widget.winner!.name}),
                textAlign: TextAlign.center,
                fontSize: context.font.medium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: context.sizes.md),
          Container(
            decoration: const BoxDecoration(
                color: AppColors.white, shape: BoxShape.circle),
            padding: EdgeInsets.all(context.sizes.xxs),
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                color: context.color.surface,
                radius: Radius.circular(context.sizes.radiusPill),
                dashPattern: const [3, 3],
              ),
              child: Container(
                margin: EdgeInsets.all(context.sizes.xxs),
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 42.r(context),
                  height: 42.r(context),
                  child: Center(
                    child: CustomText(
                      '$time',
                      color: context.color.surface,
                      fontSize: context.font.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
