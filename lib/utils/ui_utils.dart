import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// Static UI helpers: load svg/png/skin assets from network or local paths,
// and show a scale-transition dialog.
class UiUtils {
  UiUtils._();

  // app-wide flag marking whether a dialog is currently shown
  static bool isDialogActive = false;

  // Loads an svg from a URL (network) or asset path, optionally tinted.
  static SvgPicture getSvg(String path,
      {Color? color,
      BoxFit fit = BoxFit.contain,
      double? width,
      double? height}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return SvgPicture.network(
        path,
        fit: fit,
        width: width,
        height: height,
        colorFilter:
            color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      );
    }
    return SvgPicture.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      colorFilter:
          color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  // Loads a png/jpg from a URL (network) or asset path, with an error icon fallback.
  static Widget getImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Network Image
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.error, size: width ?? 24.0);
        },
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.error, size: width ?? 24.0);
        },
      );
    }
  }

  // Shows child in a scale-transition general dialog.
  static Future showDialog(BuildContext context,
      {required Widget child,
      int? millisecondTransitionDuration,
      bool? dismissible}) async {
    return await showGeneralDialog(
      context: context,
      barrierDismissible: dismissible ?? true,
      barrierLabel: 'Dismiss',
      transitionDuration:
          Duration(milliseconds: millisecondTransitionDuration ?? 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return child;
      },
    );
  }

  // Resolves a player's chosen skin to a URL or local asset path.
  static String getSkin(String skin) {
    if (skin.startsWith('http://') || skin.startsWith('https://')) {
      return skin;
    }
    return 'assets/svg/skins/$skin.svg';
  }
}
