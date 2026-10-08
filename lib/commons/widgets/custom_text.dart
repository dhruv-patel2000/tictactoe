import 'package:flutter/material.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';

// Thin wrapper over Text with app-standard defaults (color falls back to
// theme's onSurface); used in place of raw Text throughout the app.
class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign textAlign;
  final TextDecoration? decoration;
  final String? family;
  final int? maxLines;
  final bool ellipsis;

  const CustomText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.family,
    this.maxLines,
    this.ellipsis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.clip,
      maxLines: maxLines,
      style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? context.color.onSurface.withAlpha(200),
          decoration: decoration,
          fontFamily: family),
    );
  }
}
