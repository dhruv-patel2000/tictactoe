import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:dotted_border/dotted_border.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_button.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// Describes one action button rendered in a CustomDialogBox's button row.
class DialogButton {
  final String title;
  final Color? color;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool inProgress;
  final String? icon;
  const DialogButton(
      {required this.title,
      this.color,
      this.onTap,
      this.textColor,
      this.inProgress = false,
      this.icon});
}

// Standard app dialog: title + divider header, content, optional close icon,
// and an optional row of DialogButtons. Wraps CustomDialogBoxBuilder for chrome.
class CustomDialogBox extends StatelessWidget {
  final String title;
  final bool hideCloseButton;
  final Widget child;
  final List<DialogButton>? buttons;
  const CustomDialogBox(
      {super.key,
      required this.title,
      this.hideCloseButton = false,
      required this.child,
      this.buttons});

  Widget buildButtonRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.sizes.xl),
      child: Row(
        spacing: 10.r(context),
        children: [
          for (DialogButton button in buttons ?? const []) ...[
            Expanded(
              child: CustomButton(
                onTap: button.onTap,
                title: button.title,
                textColor: button.textColor,
                customWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (button.icon != null) ...[
                      CustomImage(
                        button.icon!,
                        width: 14.r(context),
                        height: 14.r(context),
                      ),
                      SizedBox(
                        width: 10.r(context),
                      ),
                    ],
                    Flexible(
                      child: CustomText(
                        button.title,
                        color: button.textColor,
                        fontSize: context.font.medium,
                        maxLines: 1,
                        ellipsis: true,
                      ),
                    )
                  ],
                ),
                type: ButtonType.primary,
                color: button.color,
                inProgress: button.inProgress,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontWeight: FontWeight.w700,
          fontSize: context.font.large,
          color: AppColors.white,
        ),
        Divider(
          endIndent: 14.r(context),
          indent: 14.r(context),
          thickness: 0.5,
          color: context.color.outline,
        ),
      ],
    );
  }

  Widget buildCloseIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, null);
      },
      child: Align(
        alignment: AlignmentDirectional.topEnd,
        child: Container(
          margin: EdgeInsetsDirectional.only(
              top: 10.r(context), end: 10.r(context)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.color.outline),
          ),
          child: Padding(
            padding: EdgeInsets.all(7.r(context)),
            child: Icon(
              Icons.close_rounded,
              color: context.color.onSurface.withAlpha(150),
              size: 14.r(context),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialogBoxBuilder(
      builder: (context) {
        return Material(
          child: Column(
            children: [
              if (!hideCloseButton) buildCloseIcon(context),
              if (hideCloseButton)
                SizedBox(
                  height: 10.r(context),
                ),
              buildHeader(context),
              child,
              buildButtonRow(context),
            ],
          ),
        );
      },
    );
  }
}

// Reusable dialog chrome: blurred backdrop, dotted border, shadowed card.
// Used directly for custom dialog content, and internally by CustomDialogBox.
class CustomDialogBoxBuilder extends StatelessWidget {
  final double? height;
  final double? width;
  final double? dottedLineDistance; // accepted but currently unused in build()
  final double?
      distanceRadius; // padding between the dotted border and its content
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? shadowBlurRadius;
  final Offset? shadowOffset;
  final Function()? onDismiss;
  final WidgetBuilder builder;

  const CustomDialogBoxBuilder({
    super.key,
    this.height,
    this.width,
    required this.builder,
    this.dottedLineDistance,
    this.distanceRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.shadowBlurRadius,
    this.shadowOffset,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Cap how wide a dialog gets on tablets — left unbounded it stretches to
    // the full screen width, which drags full-width children like buttons
    // and grid pills along with it (making them look flat/short, since
    // their height only scales modestly while their width scales with the
    // whole screen). Phones stay unaffected since screenWidth is already
    // under the cap there.
    final double effectiveWidth = width ??
        context.screenWidth
            .clamp(0, context.sizes.maxTabletContentWidth)
            .toDouble();
    final BoxDecoration innerDecoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular((borderRadius ?? 10).r(context)),
      boxShadow: [
        const BoxShadow(
          color: Color.fromARGB(173, 242, 242, 242),
          blurRadius: 0,
          spreadRadius: -10,
        ),
        BoxShadow(
          color: Theme.of(context).colorScheme.surface,
          spreadRadius: -8,
          blurRadius: shadowBlurRadius ?? 8.0,
          offset: shadowOffset ?? const Offset(0, 0),
        ),
      ],
    );

    return GestureDetector(
      onTap: onDismiss,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: FittedBox(
          fit: BoxFit.none,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              width: effectiveWidth,
              height: height,
              decoration: innerDecoration,
              child: FittedBox(
                fit: BoxFit.none,
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    color: borderColor ?? Theme.of(context).colorScheme.outline,
                    strokeWidth: 1,
                    stackFit: StackFit.loose,
                    borderPadding:
                        EdgeInsets.all(distanceRadius ?? context.sizes.lg),
                    dashPattern: const [4, 4],
                    radius: Radius.circular((borderRadius ?? 10).r(context)),
                  ),
                  child: SizedBox(
                    width: effectiveWidth,
                    height: height,
                    child: Padding(
                      padding:
                          EdgeInsets.all(distanceRadius ?? context.sizes.lg),
                      child: builder(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
