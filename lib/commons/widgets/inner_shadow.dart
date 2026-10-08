import 'package:flutter/material.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';

// Container with a layered box-shadow that fakes an inset/embossed look;
// used as the frame behind buttons, text fields, and avatars.
class InnerShadowContainer extends StatelessWidget {
  final Widget? child;
  final double? dropShadowBlurRadius;
  final Offset? dropShadowOffset;
  final Offset? translateOffset;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BoxShape shape;

  const InnerShadowContainer({
    super.key,
    this.child,
    this.dropShadowBlurRadius,
    this.translateOffset,
    this.dropShadowOffset,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.backgroundColor, // Default background color
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: translateOffset ?? Offset.zero,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor, // Set background color
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(context.sizes.radiusXs)
              : null,
          shape: shape,
          border:
              Border.all(color: const Color(0xff515151).withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffFFFFFF).withValues(alpha: 0.07),
            ),
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
              offset: const Offset(5, 5),
              spreadRadius: 0,
              blurRadius: 0,
            ),
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.23),
              blurRadius: dropShadowBlurRadius ?? 8,
              spreadRadius: 0,
              offset: dropShadowOffset ?? const Offset(3, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
