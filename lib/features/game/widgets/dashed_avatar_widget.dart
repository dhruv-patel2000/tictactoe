import 'package:flutter/material.dart';

import 'package:dotted_border/dotted_border.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// Circular player avatar with a dashed ring, used in game-over/round dialogs.
class DashedAvatarWidget extends StatelessWidget {
  final String image;
  final double? size;

  const DashedAvatarWidget({super.key, required this.image, this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.sizes.xs),
      decoration: const BoxDecoration(shape: BoxShape.circle),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: AppColors.white, width: 2.r(context)),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: AppColors.white,
          radius: Radius.circular(context.sizes.radiusPill),
          dashPattern: const [3, 3],
        ),
        child: Container(
          margin: EdgeInsets.all(context.sizes.xxs),
          decoration: const BoxDecoration(shape: BoxShape.circle),
          clipBehavior: Clip.antiAlias,
          child: CustomImage(
            image,
            width: size ?? 87.r(context),
            height: size ?? 87.r(context),
          ),
        ),
      ),
    );
  }
}
