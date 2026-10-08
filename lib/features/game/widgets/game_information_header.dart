import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/convert_number.dart';
import 'package:tic_tac_toe/utils/countdown.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/features/game/logic/game.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';

// Top info bar on MazeScreen: turn indicator, countdown timer + progress
// bar, coin/entry-fee pills, and the sound toggle.
class GameInformationHeader extends StatelessWidget {
  final Game game;
  final Countdown countdown;
  final int turnDuration;
  final bool isYourMove;
  final bool soundOn;
  final VoidCallback onToggleSound;

  const GameInformationHeader({
    super.key,
    required this.game,
    required this.countdown,
    required this.turnDuration,
    required this.isYourMove,
    required this.soundOn,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (game.restrictedMoves)
              Flexible(
                child: CustomText(
                  isYourMove
                      ? context.tr('yourMove')
                      : context.tr('opponentMove'),
                  fontSize: context.font.normal,
                  maxLines: 1,
                  ellipsis: true,
                ),
              ),
            const Spacer(),
            ValueListenableBuilder(
              valueListenable: countdown.current,
              builder: (context, value, _) {
                return CustomText(
                    context.tr('timeLabel',
                        params: {'time': value.toString().padLeft(3, '0')}),
                    fontSize: context.font.normal);
              },
            ),
          ],
        ),
        SizedBox(
          height: context.sizes.xxs,
        ),
        ValueListenableBuilder(
            valueListenable: countdown.current,
            builder: (context, value, _) {
              return SizedBox(
                height: context.sizes.xxs,
                child: Stack(
                  children: [
                    Container(
                      color: Colors.grey.shade200,
                    ),
                    LayoutBuilder(builder: (context, c) {
                      // Remaining time rescaled to 1 (turn start) -> 0 (time up);
                      // drives both the bar's shrinking width and its red lerp.
                      double minifiedValue = ConvertNumber.inRange(
                          currentValue: value.toDouble(),
                          minValue: 0,
                          maxValue: turnDuration.toDouble(),
                          newMaxValue: 0,
                          newMinValue: 1);

                      return AnimatedContainer(
                        curve: Curves.linear,
                        width: c.maxWidth * (1 - minifiedValue),
                        duration: minifiedValue == 0
                            ? Duration.zero
                            : const Duration(seconds: 1),
                        decoration: BoxDecoration(
                            color: Color.lerp(context.color.secondary,
                                Colors.red, minifiedValue)),
                      );
                    })
                  ],
                ),
              );
            }),
        SizedBox(
          height: context.sizes.lg,
        ),
        Row(
          spacing: 25.r(context),
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 10.r(context)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.r(context)),
                  border:
                      Border.all(color: context.color.onSurface.withAlpha(150)),
                ),
                child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
                  builder: (context, state) {
                    int coin = 0;
                    if (state is AuthenticatedState) {
                      coin = state.user.coin ?? 0;
                    } else if (state is AuthenticatedAsGuestState) {
                      coin = state.user.coin ?? 0;
                    }
                    return CustomText(
                      context.tr('yourCoin', params: {'amount': '$coin'}),
                      fontSize: context.font.normal,
                      fontWeight: FontWeight.bold,
                    );
                  },
                ),
              ),
            ),
            if (game.settings.fee != null)
              Expanded(
                flex: 2,
                child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 10.r(context)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r(context)),
                      color: context.color.onSurface,
                    ),
                    child: CustomText(
                        context.tr('entryCoin',
                            params: {'fee': '${game.settings.fee}'}),
                        fontSize: context.font.normal,
                        fontWeight: FontWeight.bold,
                        color: context.color.onInverseSurface)),
              ),
            FittedBox(
                fit: BoxFit.none,
                child: GestureDetector(
                  onTap: onToggleSound,
                  child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.r(context)),
                        color: context.color.onSurface,
                        border: Border.all(
                            color: context.color.onSurface.withAlpha(150)),
                      ),
                      padding: EdgeInsets.all(8.r(context)),
                      child: Icon(
                        soundOn ? Icons.volume_up : Icons.volume_off,
                        color: context.color.onInverseSurface,
                        size: 28.r(context),
                      )),
                ))
          ],
        )
      ],
    );
  }
}
