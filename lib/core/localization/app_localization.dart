import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:tic_tac_toe/core/localization/app_language.dart';

// Loads and looks up translated strings for the active locale, backed by a
// per-language JSON asset. Falls back to the default language, then to the
// raw key, so a missing translation never surfaces as an empty string.
class AppLocalization {
  AppLocalization(this.locale);

  final Locale locale;

  Map<String, String> _localizedValues =
      {}; // key -> translated string for this instance's locale

  // Shared across instances so switching locales doesn't re-read assets.
  static final Map<String, Map<String, String>> _cache = {};
  static Map<String, String> _fallback =
      {}; // default-language strings, used when a key is missing in the active locale

  static AppLocalization? of(BuildContext context) =>
      Localizations.of(context, AppLocalization);

  Future<void> loadJson() async {
    final langCode = locale.languageCode;

    // Default-language map doubles as the fallback source for missing keys.
    if (_fallback.isEmpty) {
      _fallback = await _loadAsset(AppLanguages.defaultLanguageCode);
      _cache[AppLanguages.defaultLanguageCode] = _fallback;
    }

    if (_cache.containsKey(langCode)) {
      _localizedValues = _cache[langCode]!;
      return;
    }

    final loaded = await _loadAsset(langCode);
    _cache[langCode] = loaded;
    _localizedValues = loaded;
  }

  Future<Map<String, String>> _loadAsset(String langCode) async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/languages/$langCode.json');
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  String getTranslatedValues(String key, {Map<String, String>? params}) {
    final value = _localizedValues[key];
    // Current locale -> default locale -> the key itself, in that order.
    var resolved = (value != null && value.trim().isNotEmpty)
        ? value
        : (_fallback[key] ?? key);
    if (params != null) {
      for (final entry in params.entries) {
        resolved = resolved.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return resolved;
  }

  static const LocalizationsDelegate<AppLocalization> delegate =
      _AppLocalizationDelegate();
}

// Wires AppLocalization into Flutter's localization system: declares which
// locales are supported and how to build/load an AppLocalization for one.
class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => AppLanguages.supported
      .map((language) => language.code)
      .contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) async {
    final localization = AppLocalization(locale);
    await localization.loadJson();
    return localization;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalization> old) => false;
}
