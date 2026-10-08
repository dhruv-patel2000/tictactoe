import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';

// Single image widget that picks the right renderer (asset/network, png/svg)
// from the path, with a fallback to the app logo on empty path or load error.
class CustomImage extends StatelessWidget {
  const CustomImage(this.imageUrl,
      {this.width,
      this.height,
      this.alignment = Alignment.center,
      this.fit = BoxFit.cover,
      this.color,
      super.key,
      this.cacheHeight,
      this.cacheWidth,
      this.isCircular = false,
      this.radius});

  const CustomImage.circular(
      {required this.imageUrl,
      this.width,
      this.height,
      this.alignment = Alignment.center,
      this.fit = BoxFit.cover,
      this.color,
      super.key,
      this.cacheHeight,
      this.cacheWidth,
      this.isCircular = true,
      this.radius = 0});

  final String imageUrl;

  final bool isCircular;
  final Alignment alignment;
  final BoxFit fit;
  final Color? color;
  final double? height;
  final double? width;
  final double?
      cacheHeight; // accepted but currently unused (wiring is commented out in build)
  final double?
      cacheWidth; // accepted but currently unused (wiring is commented out in build)
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final errorImg = AppIcons.appLogo;
    final image = imageUrl.isEmpty ? errorImg : imageUrl;

    final isNetworked = image.startsWith('http');
    final isSvg = image.endsWith('.svg');

    // Picks one of the 4 asset/network x png/svg renderers below.

    final colorFilter =
        color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null;

    final errorWidget = Image.asset(
      errorImg,
      width: width,
      height: height,
      fit: fit,
    );

    return Container(
      width: width,
      height: height,
      clipBehavior:
          (isCircular || (radius ?? 0) > 0) ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius ?? 0),
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle),
      child: switch ((isNetworked, isSvg)) {
        (false, false) => Image.asset(
            image,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            errorBuilder: (_, o, s) => errorWidget,
          ),
        (false, true) => SvgPicture.asset(
            image,
            width: width,
            height: height,
            colorFilter: colorFilter,
            fit: fit,
            alignment: alignment,
          ),
        (true, false) => CachedNetworkImage(
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            imageUrl: image,
            errorWidget: (_, s, o) => errorWidget,
          ),
        (true, true) => SvgPicture.network(
            image,
            width: width,
            height: height,
            colorFilter: colorFilter,
            fit: fit,
            alignment: alignment,
          ),
      },
    );
  }
}
