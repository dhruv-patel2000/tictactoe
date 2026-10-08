import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';

// Circular/rectangular avatar image with optional inner-shadow frame; used
// for player/profile avatars across the app.
class AvatarCard extends StatelessWidget {
  final String image;
  final double width;
  final double height;
  final BoxFit? fit;
  final bool? disableShadow;
  final BoxShape shape;
  const AvatarCard(
      {super.key,
      required this.image,
      this.width = 45,
      this.height = 45,
      this.fit,
      this.disableShadow,
      this.shape = BoxShape.rectangle});

  @override
  Widget build(BuildContext context) {
    if (disableShadow == true) {
      return Padding(
        padding: EdgeInsets.all(context.sizes.xxs),
        child: CustomImage(image,
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            radius:
                shape == BoxShape.circle ? max(width, height) : 6.r(context)),
      );
    }
    return InnerShadowContainer(
      height: height + 10.r(context),
      width: width + 10.r(context),
      shape: shape,
      child: Padding(
        padding: EdgeInsets.all(context.sizes.xxs),
        child: CustomImage(image,
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            radius:
                shape == BoxShape.circle ? max(width, height) : 6.r(context)),
      ),
    );
  }
}
