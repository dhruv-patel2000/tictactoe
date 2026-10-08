import 'package:flutter/material.dart';
import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/color_extension.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// Shared button used across the app; renders as one of three visual styles
// (ButtonType.shadow/primary/gradient) and shows an inline progress spinner
// in place of the label when inProgress is true.
class CustomButton extends StatefulWidget {
  final String? title;
  final Widget? customWidget;
  final VoidCallback? onTap;
  final ButtonType type;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final double? radius;
  final Color? color;
  final Color? textColor;
  final bool inProgress;
  const CustomButton(
      {super.key,
      this.padding,
      this.title,
      this.textColor,
      required this.onTap,
      this.type = ButtonType.shadow,
      this.width,
      this.height,
      this.customWidget,
      this.radius,
      this.color,
      this.inProgress = false});

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  // Drives the pressed visual (shadow squish / gradient shift); a null onTap
  // means "disabled", so it's initialized as permanently pressed-looking.
  late bool isPressed = widget.onTap != null ? false : true;

  Widget buildContent() {
    if (widget.customWidget != null) {
      return widget.customWidget!;
    }

    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: CustomText(
            widget.title ?? '',
            fontSize: context.font.medium,
            color: widget.textColor ?? AppColors.white,
            fontWeight: FontWeight.w700,
            maxLines: 1,
            ellipsis: true,
          ),
        ),
      ],
    ));
  }

  Widget buildTitle() {
    final Widget content = buildContent();
    if (!widget.inProgress) {
      return content;
    }

    // The label stays in the layout — just invisible — so the button keeps the
    // exact same size while the spinner is drawn on top of it.
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0, child: content),
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.textColor ?? AppColors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == ButtonType.shadow) {
      return GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            // Briefly flash the pressed state for tactile feedback, then
            // invoke the callback.
            isPressed = true;
            setState(() {});

            Future.delayed(const Duration(milliseconds: 150)).then((value) {
              isPressed = false;
              setState(() {});
            });
            widget.onTap?.call();
          }
        },
        child: InnerShadowContainer(
          child: Container(
            padding: widget.padding,
            width: widget.width,
            height: widget.height,
            child: buildTitle(),
          ),
        ),
      );
    }

    if (widget.type == ButtonType.primary) {
      final Color fillColor = widget.color ?? context.color.secondary;
      return MaterialButton(
        minWidth: widget.width,
        padding: widget.padding,
        textColor: widget.textColor,
        height: widget.height ?? 40.r(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.radius ?? 6)),
        color: fillColor,
        // A disabled button here only ever means "busy" or "blocked by another
        // action in flight", so it keeps its normal look instead of greying
        // out and visually vanishing.
        disabledColor: fillColor,
        disabledTextColor: widget.textColor,
        disabledElevation: 2,
        onPressed: widget.onTap,
        child: buildTitle(),
      );
    }

    if (widget.type == ButtonType.gradient) {
      assert(widget.color != null, 'Color must not be null');
      return Transform.translate(
        offset: isPressed ? const Offset(1, 2) : Offset.zero,
        child: GestureDetector(
          onTapDown: (details) {
            if (widget.onTap != null) {
              isPressed = true;
              setState(() {});
            }
          },
          onTapUp: (f) async {
            if (widget.onTap != null) {
              await Future.delayed(const Duration(milliseconds: 150));
              isPressed = false;
              setState(() {});
              widget.onTap?.call();
            }
          },
          onTapCancel: () {
            isPressed = false;
            setState(() {});
          },
          child: Container(
            width: widget.width,
            height: widget.height ?? double.maxFinite,
            decoration: BoxDecoration(
              boxShadow: [
                if (!isPressed)
                  BoxShadow(
                    blurRadius: 8,
                    color: context.color.surface,
                    offset: const Offset(3, 3),
                  ),
              ],
              borderRadius: BorderRadius.circular(widget.radius ?? 6),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.05, 1.0],
                colors: [
                  widget.color!.brighten(isPressed ? 0.3 : 0.4),
                  widget.color!.darken(isPressed ? 0.6 : 0.5),
                ],
              ),
            ),
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: buildTitle(),
            ),
          ),
        ),
      );
    }

    return Container();
  }
}
