import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/ui_utils.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/features/skins/models/skin_model.dart';

/// Asks the player to confirm spending [Skin.price] coins before it's bought
/// and equipped. Resolves to `true` on confirm, `null`/`false` otherwise.
class SkinConfirmationDialog extends StatelessWidget {
  final Skin skin;
  const SkinConfirmationDialog({super.key, required this.skin});

  @override
  Widget build(BuildContext context) {
    return CustomDialogBox(
      title: context.tr('confirmPurchase'),
      buttons: [
        DialogButton(
          title: context.tr('no'),
          color: context.color.secondary,
          textColor: Colors.white,
          onTap: () => Navigator.pop(context, false),
        ),
        DialogButton(
          title: context.tr('yesBuy'),
          color: context.color.tertiary,
          textColor: Colors.white,
          onTap: () => Navigator.pop(context, true),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.sizes.md, vertical: context.sizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImage(UiUtils.getSkin(skin.skinX),
                    width: context.sizes.xxxl, height: context.sizes.xxxl),
                SizedBox(width: context.sizes.sm),
                CustomImage(UiUtils.getSkin(skin.skinO),
                    width: context.sizes.xxxl, height: context.sizes.xxxl),
              ],
            ),
            SizedBox(height: context.sizes.sm),
            CustomText(
              skin.name,
              fontWeight: FontWeight.w700,
              fontSize: context.font.large,
            ),
            SizedBox(height: context.sizes.xs),
            CustomText(
              context.tr('areYouSurePurchaseSkin', params: {
                'price': '${skin.price}',
              }),
              fontSize: context.font.normal,
              textAlign: TextAlign.center,
              color: context.color.onSurface.withAlpha(200),
            ),
            SizedBox(height: context.sizes.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImage(AppIcons.coin,
                    width: 18.r(context), height: 18.r(context)),
                SizedBox(width: context.sizes.xxs),
                CustomText(
                  '${skin.price}',
                  fontSize: context.font.medium,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
