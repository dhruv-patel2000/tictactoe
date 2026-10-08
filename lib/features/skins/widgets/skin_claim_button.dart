import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/color_extension.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/ui_utils.dart';
import 'package:tic_tac_toe/commons/widgets/custom_button.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/features/skins/models/skin_model.dart';
import 'package:tic_tac_toe/features/skins/widgets/skin_confirmation_dialog.dart';

// Button on a skin tile that shows Free/price/Purchased/Active and drives
// the purchase-confirm-activate flow for a single skin.
class SkinClaimButton extends StatelessWidget {
  final Skin skin;
  final bool isPurchased;
  final bool isActive;
  const SkinClaimButton(
      {super.key,
      required this.skin,
      required this.isPurchased,
      required this.isActive});

  Color _getButtonColor(BuildContext context) {
    if (isActive) {
      return Colors.lightGreenAccent;
    }
    if (isPurchased) {
      return context.color.secondary.brighten(0.2);
    } else {
      return context.color.tertiary.brighten(0.3);
    }
  }

  void _showInsufficientCoins(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('notEnoughCoinsToPlay', params: {
          'amount': '${skin.price}',
        })),
      ),
    );
  }

  Future<void> _claim(BuildContext context) async {
    // Already owned: tapping just equips it, no coin/dialog flow needed.
    if (isPurchased) {
      await DatabaseService.instance.activateSkin(skin);
      return;
    }

    if (skin.price > 0) {
      final user = await DatabaseService.instance.getUser();
      if (!context.mounted) return;
      if ((user.coin ?? 0) < skin.price) {
        _showInsufficientCoins(context);
        return;
      }

      final confirmed = await UiUtils.showDialog(context,
          child: SkinConfirmationDialog(skin: skin));
      if (confirmed != true) return;
    }

    // purchaseSkin re-checks the balance server-side; a false result covers
    // races (e.g. coins spent elsewhere between the check above and now).
    final bought = await DatabaseService.instance.purchaseSkin(skin);
    if (!bought && context.mounted) _showInsufficientCoins(context);
  }

  Widget _label(BuildContext context, String text) {
    return Center(
      child: CustomText(
        text,
        color: context.color.surface,
        fontSize: context.font.large,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFreeAndUnowned = !isPurchased && skin.price == 0;

    return CustomButton(
      onTap: isActive ? null : () => _claim(context),
      customWidget: isActive
          ? _label(context, context.tr('active'))
          : isFreeAndUnowned
              ? _label(context, context.tr('free'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!isPurchased) ...{
                          CustomImage(
                            AppIcons.coin,
                            width: 18.r(context),
                            height: 18.r(context),
                          ),
                          SizedBox(
                            width: context.sizes.xxs,
                          ),
                        },
                        AutoSizeText(
                            isPurchased
                                ? context.tr('purchased')
                                : '${skin.price}',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: isPurchased
                                  ? context.font.normal
                                  : context.font.large,
                              color: context.color.surface,
                              fontWeight: isPurchased
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                            )),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.sizes.md, vertical: 4.r(context)),
                      decoration: BoxDecoration(
                          color: context.color.surface,
                          borderRadius:
                              BorderRadius.circular(context.sizes.radiusLg)),
                      child: AutoSizeText(
                        isPurchased
                            ? context.tr('useNow')
                            : context.tr('claim'),
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    )
                  ],
                ),
      color: _getButtonColor(context),
      type: ButtonType.gradient,
    );
  }
}
