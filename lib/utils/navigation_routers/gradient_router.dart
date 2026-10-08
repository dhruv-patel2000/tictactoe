import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// Custom PageRoute used by screens that need the shared gradient/maze
// background behind their content, with a fade (or native iOS) transition.
class GradientRouter extends PageRoute<void> {
  // builds the screen content placed over the gradient/maze background
  final WidgetBuilder builder;
  // overrides barrierDismissible; null falls back to the PageRoute default
  final bool? barrierDismiss;
  // skips the corner maze decoration for screens that don't want it
  final bool disableMazeBackground;

  GradientRouter({
    required this.builder,
    this.barrierDismiss,
    super.settings,
    this.disableMazeBackground = false,
  }) : super(fullscreenDialog: false);

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => barrierDismiss ?? super.barrierDismissible;

  @override
  String get barrierLabel => "blurred";

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final Widget result = builder(context);
    final Widget screen = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.screenBackgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          if (!disableMazeBackground)
            Positioned(
              top: -130,
              left: -120,
              child: Image.asset(AppIcons.mazeIcon),
            ),
          if (!disableMazeBackground)
            Positioned(
              bottom: -140,
              right: -130,
              child: Image.asset(AppIcons.mazeIcon),
            ),
          result,
        ],
      ),
    );

    if (Platform.isIOS) {
      // Use the platform's native page transition (e.g. Cupertino slide) on iOS.
      final PageTransitionsTheme theme = Theme.of(context).pageTransitionsTheme;

      return theme.buildTransitions(
        this,
        context,
        animation,
        Animation.fromValueListenable(ValueNotifier(0)),
        screen,
      );
    }
    // Non-iOS platforms fall back to a plain fade transition.
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: screen,
    );
  }
}
