// One selectable app language: its locale code plus display names.
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

// Registry of languages offered in the app's language picker.
abstract class AppLanguages {
  static const String defaultLanguageCode =
      'en'; // fallback/default locale used when no other language is selected

  static const List<AppLanguage> supported = [
    AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
    AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    AppLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
    AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
    AppLanguage(
      code: 'pt',
      name: 'Portuguese (Brazilian)',
      nativeName: 'Português (Brasil)',
    ),
    AppLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
    AppLanguage(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia'),
  ];
}
