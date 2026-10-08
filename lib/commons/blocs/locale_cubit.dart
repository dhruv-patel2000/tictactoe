import 'package:flutter/material.dart';

import 'package:bloc/bloc.dart';

import 'package:tic_tac_toe/utils/local_storage.dart';
import 'package:tic_tac_toe/core/constants/settings.dart';
import 'package:tic_tac_toe/core/localization/app_language.dart';

// Cubit: holds the app's active Locale, persisting the user's choice and
// falling back to the device locale (then a default) when none is saved.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(_resolveInitialLocale());

  static Locale _resolveInitialLocale() {
    // Preference order: saved user choice, then device locale, then default.
    final savedCode = LocalStorage.getLanguageCode();
    if (savedCode != null &&
        AppLanguages.supported.any((language) => language.code == savedCode)) {
      return Locale(savedCode);
    }

    final deviceCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (AppLanguages.supported.any((language) => language.code == deviceCode)) {
      return Locale(deviceCode);
    }

    return const Locale(AppSettings.defaultLanguageCode);
  }

  Future<void> changeLocale(String languageCode) async {
    if (state.languageCode == languageCode) return;
    await LocalStorage.setLanguageCode(languageCode);
    emit(Locale(languageCode));
  }
}
