import 'package:flutter/material.dart';

/// A language supported by the app, shown using its native display name.
class AppLanguage {
  const AppLanguage({required this.code, required this.name});

  final String code;
  final String name;
}

/// Only languages with a complete in-app translation are selectable.
///
/// Display names use each language's own name, so the picker remains useful
/// regardless of the language currently active in the app.
const List<AppLanguage> appLanguages = <AppLanguage>[
  AppLanguage(code: 'ar', name: 'العربية'),
  AppLanguage(code: 'de', name: 'Deutsch'),
  AppLanguage(code: 'en', name: 'English'),
  AppLanguage(code: 'es', name: 'Español'),
  AppLanguage(code: 'fr', name: 'Français'),
  AppLanguage(code: 'ps', name: 'پښتو'),
  AppLanguage(code: 'tr', name: 'Türkçe'),
  AppLanguage(code: 'ur', name: 'اردو'),
];

const List<Locale> supportedAppLocales = <Locale>[
  Locale('ar'),
  Locale('de'),
  Locale('en'),
  Locale('es'),
  Locale('fr'),
  Locale('ps'),
  Locale('tr'),
  Locale('ur'),
];

String languageName(String code) {
  for (final AppLanguage language in appLanguages) {
    if (language.code == code) return language.name;
  }
  return code;
}
