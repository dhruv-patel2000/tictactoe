import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// "Watch ad" shop tile button. Reacts to raw pointer events instead of
// arena-mediated tap recognition, treating any small-movement down->up as a
// tap: plain GestureDetector.onTap loses the gesture arena to the ancestor
// GridView's scroll recognizer on some OEM devices (observed consistently on
// ColorOS hardware, even with a zero-movement tap).
class WatchAdButton extends StatefulWidget {
  final bool isWaitingForRewardedAd;
  final VoidCallback onWatchAd;

  const WatchAdButton({
    super.key,
    required this.isWaitingForRewardedAd,
    required this.onWatchAd,
  });

  @override
  State<WatchAdButton> createState() => _WatchAdButtonState();
}

class _WatchAdButtonState extends State<WatchAdButton> {
  // Pointer's initial position; compared against pointer-up to detect a tap vs. a scroll.
  Offset? _pointerDownPosition;

  /// Tracked so a second finger landing anywhere can't overwrite the position
  /// this button is measuring its own pointer's movement against.
  int? _pointerId;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _pointerId = event.pointer;
        _pointerDownPosition = event.position;
      },
      onPointerUp: (event) {
        if (event.pointer != _pointerId) return;
        final Offset? down = _pointerDownPosition;
        _pointerId = null;
        _pointerDownPosition = null;
        if (down == null) return;
        if ((event.position - down).distance <= 24) widget.onWatchAd();
      },
      onPointerCancel: (event) {
        if (event.pointer != _pointerId) return;
        _pointerId = null;
        _pointerDownPosition = null;
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.sizes.sm, vertical: context.sizes.xs),
        decoration: BoxDecoration(
          color: context.color.secondary,
          borderRadius: BorderRadius.circular(context.sizes.radiusLg),
        ),
        child: widget.isWaitingForRewardedAd
            ? SizedBox(
                width: context.sizes.md,
                height: context.sizes.md,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.white),
              )
            : CustomText(
                context.tr('earnCoinsByViewingAds'),
                textAlign: TextAlign.center,
                fontSize: context.font.medium,
                maxLines: 2,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
      ),
    );
  }
}
