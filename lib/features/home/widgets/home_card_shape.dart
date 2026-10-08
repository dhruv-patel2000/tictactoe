import 'package:flutter/material.dart';

import 'package:tic_tac_toe/core/theme/colors.dart';

// Custom notched/rounded outline for HomeCard, built as an explicit path.
class HomeCardShapeBorder extends ShapeBorder {
  final bool
      usePadding; // reserves bottom inset (see dimensions) for shadow/decoration below the shape
  final Color borderColor;
  final double borderWidth;
  const HomeCardShapeBorder(
      {this.usePadding = false,
      this.borderColor = AppColors.black,
      this.borderWidth = 1.0});

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: usePadding ? 20 : 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();
    const roundnessFactor = 20.0;

    path.moveTo(rect.left, rect.top + (rect.height * 0.33));
    path.lineTo(rect.left, rect.bottom - roundnessFactor);
    path.quadraticBezierTo(
        rect.left, rect.bottom, rect.left + roundnessFactor, rect.bottom);
    path.lineTo(rect.right - roundnessFactor, rect.bottom);
    path.quadraticBezierTo(
        rect.right, rect.bottom, rect.right, rect.bottom - roundnessFactor);
    path.lineTo(rect.right, rect.top + roundnessFactor * 2);
    path.quadraticBezierTo(rect.right, rect.top + roundnessFactor,
        rect.right - roundnessFactor * 1.5, rect.top + roundnessFactor * 1.5);
    path.lineTo(rect.left + roundnessFactor * 0.6,
        rect.top + (rect.height * 0.33) - roundnessFactor * 0.3);
    path.quadraticBezierTo(rect.left, rect.top + (rect.height * 0.33),
        rect.left, rect.top + (rect.height * 0.33) + roundnessFactor);

    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();
    const roundnessFactor = 15.0;
    const leftSide = 0.5;
    path.moveTo(rect.left, rect.top + (rect.height * leftSide));

    path.lineTo(rect.left, rect.bottom - roundnessFactor);
    path.quadraticBezierTo(
        rect.left, rect.bottom, rect.left + roundnessFactor, rect.bottom);
    path.lineTo(rect.right - roundnessFactor, rect.bottom);
    path.quadraticBezierTo(
        rect.right, rect.bottom, rect.right, rect.bottom - roundnessFactor);
    path.lineTo(rect.right, rect.top + roundnessFactor * 2);
    path.quadraticBezierTo(rect.right, rect.top + roundnessFactor,
        rect.right - roundnessFactor * 1.5, rect.top + roundnessFactor * 1.5);
    path.lineTo(rect.left + roundnessFactor * 0.6,
        rect.top + (rect.height * leftSide) - roundnessFactor * 0.3);
    path.quadraticBezierTo(rect.left, rect.top + (rect.height * leftSide),
        rect.left, rect.top + (rect.height * leftSide) + roundnessFactor);

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final path = getOuterPath(rect, textDirection: textDirection);

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

// Clips content to the path from [_buildPath0], centered within its bounds.
class ShapePathClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path0 = _buildPath0(size);
    final Rect combinedBounds = path0.getBounds();
    final dx = size.width / 2 - combinedBounds.center.dx;
    final dy = size.height / 2 - combinedBounds.center.dy;
    final centerOffset = Offset(dx, dy);

    final centeredPath0 = path0.shift(centerOffset);
    final clipPath = Path();
    clipPath.addPath(centeredPath0, Offset.zero);
    return clipPath;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Path _buildPath0(Size size) {
  return Path()
    ..moveTo(size.width * 0.0264, size.height * 0.0113)
    ..lineTo(size.width * 0.9736, size.height * 0.4173)
    ..quadraticBezierTo(
        size.width, size.height * 0.4286, size.width, size.height * 0.4643)
    ..lineTo(size.width, size.height * 0.9643)
    ..quadraticBezierTo(
        size.width, size.height, size.width * 0.9722, size.height)
    ..lineTo(size.width * 0.0278, size.height)
    ..quadraticBezierTo(0, size.height, 0, size.height * 0.9643)
    ..lineTo(0, size.height * 0.0357)
    ..quadraticBezierTo(0, 0, size.width * 0.0264, size.height * 0.0113)
    ..close();
}
