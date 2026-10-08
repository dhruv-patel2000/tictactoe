import 'package:flutter/material.dart';

import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/shop/models/shop_item_model.dart';
import 'package:tic_tac_toe/features/shop/widgets/watch_ad_button.dart';

// One coin-pack (or "watch ad") tile in the shop grid.
class ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final Product? product;
  final bool isPurchasing;
  final bool isWaitingForRewardedAd;
  final VoidCallback onBuy;
  final VoidCallback onWatchAd;

  const ShopItemCard({
    super.key,
    required this.item,
    this.product,
    required this.isPurchasing,
    required this.isWaitingForRewardedAd,
    required this.onBuy,
    required this.onWatchAd,
  });

  Widget _buildArtwork(BuildContext context) {
    if (item.isAd) {
      return CustomImage(AppIcons.ads, fit: BoxFit.contain);
    }
    final image = item.image;
    if (image != null && image.isNotEmpty) {
      return CustomImage(image, fit: BoxFit.contain);
    }
    return CustomImage(item.coinArtwork, fit: BoxFit.contain);
  }

  Widget _buildPriceButton(BuildContext context) {
    final String label = product?.displayPrice ?? item.priceLabel;

    return GestureDetector(
      onTap: isPurchasing ? null : onBuy,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.sizes.lg, vertical: 9.r(context)),
        decoration: BoxDecoration(
          color: context.color.secondary,
          borderRadius: BorderRadius.circular(context.sizes.radiusLg),
        ),
        child: isPurchasing
            ? SizedBox(
                width: context.sizes.md,
                height: context.sizes.md,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.white),
              )
            : CustomText(
                label,
                fontSize: context.font.normal,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InnerShadowContainer(
      child: ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(context.sizes.radiusXs),
        child: Stack(
          children: [
            PositionedDirectional(
                top: 60.r(context),
                start: 10.r(context),
                child: CustomImage(AppIcons.starGroup)),
            PositionedDirectional(
                bottom: 36.r(context),
                end: -6.r(context),
                child: CustomImage(AppIcons.starGroup)),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  color: context.color.secondary,
                  padding: EdgeInsets.symmetric(vertical: 10.r(context)),
                  child: CustomText(
                    item.title,
                    textAlign: TextAlign.center,
                    fontSize: context.font.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(context.sizes.sm),
                    child: _buildArtwork(context),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.sizes.sm, 0, context.sizes.sm, context.sizes.md),
                  child: item.isAd
                      ? WatchAdButton(
                          isWaitingForRewardedAd: isWaitingForRewardedAd,
                          onWatchAd: onWatchAd,
                        )
                      : _buildPriceButton(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
