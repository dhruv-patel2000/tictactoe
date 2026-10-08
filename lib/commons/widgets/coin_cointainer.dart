import 'package:flutter/material.dart';
import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/convert_number.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';

// Pill showing a coin icon plus a compact-formatted coin count; used for
// balance displays and selectable coin-amount options (e.g. in shop/bets).
class CoinContainer extends StatelessWidget {
  final int coins;
  final bool selected;
  const CoinContainer({super.key, required this.coins, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.sizes.md, vertical: 7.r(context)),
      decoration: BoxDecoration(
        border: selected
            ? null
            : Border.all(color: context.color.onSurface.withAlpha(200)),
        color: selected ? context.color.secondary : null,
        borderRadius: BorderRadius.circular(context.sizes.radiusXs),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImage(
            AppIcons.coin,
            width: 18.r(context),
            height: 18.r(context),
          ),
          SizedBox(
            width: 6.r(context),
          ),
          CustomText(
            ConvertNumber.formatCompact(coins),
            fontSize: context.font.large,
            color: context.color.onSurface.withAlpha(255),
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}
