import 'package:flutter/material.dart';
import 'package:tic_tac_toe/core/localization/app_localization.dart';
import 'package:tic_tac_toe/core/theme/app_sizes.dart';
import 'package:tic_tac_toe/core/theme/font_sizes.dart';

/// Shortcuts hung off BuildContext for screen size, theme colors, fonts,
/// responsive sizing, and localized string lookup — used across all screens.
extension CustomContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  ColorScheme get color => Theme.of(this).colorScheme;

  ///I created different Font class to limit textTheme values, let's assume if some one is using context.font and he is getting too may options related to text theme so how will he know which one is for use??
  ///So in theme.dart file i have created Font class which will give limited numbers of getters
  FontSizes get font => FontSizes(this);

  /// Responsive spacing/sizing/radius tokens — scales with device size.
  AppSizes get sizes => AppSizes(this);

  /// Looks up [key] in `assets/languages/<locale>.json`, falling back to
  /// the English value (or the key itself) when missing/untranslated.
  /// [params] fill `{token}` placeholders in the translated string.
  String tr(String key, {Map<String, String>? params}) =>
      AppLocalization.of(this)?.getTranslatedValues(key, params: params) ?? key;
}
