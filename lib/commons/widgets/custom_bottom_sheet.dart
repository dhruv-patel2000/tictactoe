import 'package:flutter/material.dart';

import 'package:dotted_border/dotted_border.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';

/// Standard bottom sheet chrome (rounded top corners, drag handle,
/// optional title) shared by every bottom-sheet-presented screen.
Future<T?> showCustomBottomSheet<T>(
  BuildContext context, {
  String? title,
  required Widget child,
  Color? backgroundColor,
  bool enableDrag = true,
  bool isDismissible = true,
  bool useSafeArea = true,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    enableDrag: enableDrag,
    isDismissible: isDismissible,
    barrierColor: Colors.black54,
    backgroundColor: backgroundColor ?? context.color.surfaceContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(context.sizes.radiusXl),
        topRight: Radius.circular(context.sizes.radiusXl),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Padding(
          padding: EdgeInsets.all(context.sizes.xs),
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
              color: context.color.outline,
              strokeWidth: 1,
              dashPattern: const [4, 4],
              padding: EdgeInsets.zero,
              radius: Radius.circular(context.sizes.radiusXl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDragHandle) const CustomBottomSheetDragHandle(),
                if (title != null) ...[
                  SizedBox(height: context.sizes.xs),
                  CustomText(
                    title,
                    fontSize: context.font.large,
                    fontWeight: FontWeight.w700,
                  ),
                  SizedBox(height: context.sizes.xs),
                ],
                Flexible(child: child),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// The small pill handle rendered at the top of every custom bottom sheet.
class CustomBottomSheetDragHandle extends StatelessWidget {
  const CustomBottomSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: context.sizes.md, vertical: context.sizes.md),
      child: Container(
        width: context.sizes.xxxl,
        height: context.sizes.xxs,
        decoration: BoxDecoration(
          color: context.color.onSurface.withAlpha(50),
          borderRadius: BorderRadius.circular(10.r(context)),
        ),
      ),
    );
  }
}
