import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

// Thin static wrapper around SharedPreferences for persisting auth/guest
// state, language, and sound settings across app restarts.
class LocalStorage {
  static const String _languageCodeKey = 'languageCode';
  static const String _soundEnabledKey = 'soundEnabled';

  // cached instance; set once by init() at startup
  static SharedPreferences? _preferences;

  // Must be awaited before any other method is used (called once at startup).
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static FutureOr<void> setString(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  static FutureOr<String?> getString(String key) async {
    return _preferences?.getString(key);
  }

  static Future<bool> checkAuthentication() async {
    return _preferences?.getBool('isLoggedIn') ?? false;
  }

  static Future<void> setUserAuthenticated() async {
    await _preferences?.setBool('isLoggedIn', true);
  }

  static Future<void> setUserNotAuthenticated() async {
    await _preferences?.setBool('isLoggedIn', false);
  }

  static Future<void> setUserIsGuest() async {
    await _preferences?.setBool('isGuest', true);
  }

  static Future<void> setUserIsNotGuest() async {
    await _preferences?.setBool('isGuest', false);
  }

  static Future<bool> isGuest() async {
    return _preferences?.getBool('isGuest') ?? false;
  }

  static Future<bool> logoutUser() async {
    await setUserIsNotGuest();
    await setUserNotAuthenticated();

    return true;
  }

  static Future<void> setLanguageCode(String languageCode) async {
    await _preferences?.setString(_languageCodeKey, languageCode);
  }

  static String? getLanguageCode() {
    return _preferences?.getString(_languageCodeKey);
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    await _preferences?.setBool(_soundEnabledKey, enabled);
  }

  static bool isSoundEnabled() {
    return _preferences?.getBool(_soundEnabledKey) ?? true;
  }
}
