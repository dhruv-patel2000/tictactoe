import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/ui_utils.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/commons/widgets/marquee.dart';
import 'package:tic_tac_toe/features/skins/models/skin_model.dart';
import 'package:tic_tac_toe/features/skins/widgets/skin_claim_button.dart';

// Single row in the skins list: skin preview icons + name, with the claim
// button on the trailing side.
class SkinTile extends StatelessWidget {
  final Skin skin;
  final bool isPurchased;
  final bool isActive;
  const SkinTile(
      {super.key,
      required this.skin,
      required this.isPurchased,
      required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.r(context),
      child: Row(
        spacing: 11.r(context),
        children: [
          Expanded(
            flex: 5,
            child: InnerShadowContainer(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 6.0.r(context), horizontal: context.sizes.md),
                child: Row(
                  children: [
                    CustomImage(
                      UiUtils.getSkin(skin.skinX),
                      width: context.sizes.xl,
                      height: context.sizes.xl,
                    ),
                    SizedBox(width: 18.r(context)),
                    CustomImage(
                      UiUtils.getSkin(skin.skinO),
                      width: context.sizes.xl,
                      height: context.sizes.xl,
                    ),
                    SizedBox(width: 17.r(context)),
                    Expanded(
                      child: MarqueeWidget(
                        child: CustomText(
                          skin.name,
                          fontSize: context.font.xL,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Expanded(
              flex: 2,
              child: SkinClaimButton(
                skin: skin,
                isPurchased: isPurchased,
                isActive: isActive,
              ))
        ],
      ),
    );
  }
}
