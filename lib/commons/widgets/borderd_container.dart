import 'package:flutter/cupertino.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';

// Simple bordered/rounded box wrapper with centered child content.
class BorderContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  const BorderContainer(
      {super.key,
      required this.child,
      this.padding,
      this.color,
      this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: borderColor ?? context.color.onSurface.withAlpha(200)),
        borderRadius: BorderRadius.circular(context.sizes.radiusXs),
        color: color,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(context.sizes.xxs),
        child: Center(child: child),
      ),
    );
  }
}
