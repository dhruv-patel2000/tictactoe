import 'package:flutter/material.dart';

import 'package:tic_tac_toe/core/theme/colors.dart';

// Glowing border used to highlight the player whose turn it currently is.
class NeonBorderContainer extends BoxBorder {
  final Color baseColor;

  const NeonBorderContainer(this.baseColor);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    const double strokeMultiplier = 0.7;
    final Paint paintShadow = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.0 * strokeMultiplier;

    final Paint paintBorder = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0 * strokeMultiplier;
    final Paint paintWhiteShadow = Paint()
      ..color = AppColors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.0 * strokeMultiplier
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawLine(rect.topLeft, rect.topRight, paintWhiteShadow);
    canvas.drawLine(rect.topRight, rect.bottomRight, paintWhiteShadow);
    canvas.drawLine(rect.bottomRight, rect.bottomLeft, paintWhiteShadow);
    canvas.drawLine(rect.bottomLeft, rect.topLeft, paintWhiteShadow);

    canvas.drawLine(rect.topLeft, rect.topRight, paintShadow);
    canvas.drawLine(rect.topRight, rect.bottomRight, paintShadow);
    canvas.drawLine(rect.bottomRight, rect.bottomLeft, paintShadow);
    canvas.drawLine(rect.bottomLeft, rect.topLeft, paintShadow);

    canvas.drawLine(rect.topLeft, rect.topRight, paintBorder);
    canvas.drawLine(rect.topRight, rect.bottomRight, paintBorder);
    canvas.drawLine(rect.bottomRight, rect.bottomLeft, paintBorder);
    canvas.drawLine(rect.bottomLeft, rect.topLeft, paintBorder);
  }

  @override
  ShapeBorder scale(double t) {
    return this;
  }

  @override
  BorderSide get bottom => const BorderSide(color: Colors.transparent);

  @override
  BorderSide get top => const BorderSide(color: Colors.transparent);
}
