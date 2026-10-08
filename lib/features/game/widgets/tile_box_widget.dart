import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// Renders one squircle-shaped cell of the tic-tac-toe board; displays the
// X/O skin passed in as child. Tap handling lives in the parent GridView.
class TileBoxWidget extends StatefulWidget {
  final double size;
  final Color color;
  final Widget? child;

  const TileBoxWidget({
    super.key,
    this.size = 100.0,
    this.color = AppColors.white,
    this.child,
  });

  @override
  State<TileBoxWidget> createState() => _TileBoxWidgetState();
}

class _TileBoxWidgetState extends State<TileBoxWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: ShapeDecoration(
        shape: Squircle(borderColor: context.color.outline),
        shadows: [
          BoxShadow(color: const Color(0xffFFFFFF).withValues(alpha: 0.07)),
          BoxShadow(
            color: context.color.surface.withValues(alpha: 0.4),
            offset: const Offset(5, 5),
            spreadRadius: 8,
            blurRadius: 5,
          ),
          BoxShadow(
              color: context.color.surface.withValues(alpha: 0.23),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(3, 3)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.sizes.sm),
        child: FittedBox(fit: BoxFit.scaleDown, child: widget.child),
      ),
    );
  }
}

// Rounded-square ("squircle") shape used for the tile's outline/clip.
class Squircle extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;

  const Squircle({
    this.borderColor = AppColors.white,
    this.borderWidth = 1,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();

    double width = rect.width;
    double height = rect.height;

    double minDimension = width < height ? width : height;
    double
        borderMargin = // corner-rounding inset, scaled to the shorter side so it stays proportional
        minDimension * 0.11;

    path.moveTo(rect.left + borderMargin, rect.top + borderMargin);

    path.cubicTo(
      rect.left + width / 4,
      rect.top,
      rect.left + (width / 4) * 3,
      rect.top,
      rect.right - borderMargin,
      rect.top + borderMargin,
    );

    path.cubicTo(
      rect.right,
      rect.top + height / 4,
      rect.right,
      rect.top + (height / 4) * 3,
      rect.right - borderMargin,
      rect.bottom - borderMargin,
    );

    path.cubicTo(
      rect.left + (width / 4) * 3,
      rect.bottom,
      rect.left + width / 4,
      rect.bottom,
      rect.left + borderMargin,
      rect.bottom - borderMargin,
    );

    path.cubicTo(
      rect.left,
      rect.top + (height / 4) * 3,
      rect.left,
      rect.top + height / 4,
      rect.left + borderMargin,
      rect.top + borderMargin,
    );

    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();

    double width = rect.width;
    double height = rect.height;

    double minDimension = width < height ? width : height;
    double borderMargin = minDimension * 0.11;

    path.moveTo(rect.left + borderMargin, rect.top + borderMargin);

    path.cubicTo(
      rect.left + width / 4,
      rect.top,
      rect.left + (width / 4) * 3,
      rect.top,
      rect.right - borderMargin,
      rect.top + borderMargin,
    );

    path.cubicTo(
      rect.right,
      rect.top + height / 4,
      rect.right,
      rect.top + (height / 4) * 3,
      rect.right - borderMargin,
      rect.bottom - borderMargin,
    );

    path.cubicTo(
      rect.left + (width / 4) * 3,
      rect.bottom,
      rect.left + width / 4,
      rect.bottom,
      rect.left + borderMargin,
      rect.bottom - borderMargin,
    );

    path.cubicTo(
      rect.left,
      rect.top + (height / 4) * 3,
      rect.left,
      rect.top + height / 4,
      rect.left + borderMargin,
      rect.top + borderMargin,
    );

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    var path = getOuterPath(rect, textDirection: textDirection);

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return this;
  }
}
