import 'package:flutter/material.dart';

/// A language supported by the app, shown using its native display name.
class AppLanguage {
  const AppLanguage({required this.code, required this.name});

  final String code;
  final String name;
}

/// Kept in alphabetical order by the German language name used in settings.
const List<AppLanguage> appLanguages = <AppLanguage>[
  AppLanguage(code: 'ar', name: 'Arabisch'),
  AppLanguage(code: 'bn', name: 'Bengali'),
  AppLanguage(code: 'de', name: 'Deutsch'),
  AppLanguage(code: 'en', name: 'Englisch'),
  AppLanguage(code: 'fr', name: 'Französisch'),
  AppLanguage(code: 'ha', name: 'Hausa'),
  AppLanguage(code: 'id', name: 'Indonesisch / Malaiisch'),
  AppLanguage(code: 'jv', name: 'Javanisch'),
  AppLanguage(code: 'nl', name: 'Niederländisch'),
  AppLanguage(code: 'ps', name: 'Paschtunisch'),
  AppLanguage(code: 'fa', name: 'Persisch / Farsi / Dari'),
  AppLanguage(code: 'ru', name: 'Russisch'),
  AppLanguage(code: 'so', name: 'Somali'),
  AppLanguage(code: 'sw', name: 'Suaheli'),
  AppLanguage(code: 'ce', name: 'Tschetschenisch'),
  AppLanguage(code: 'tr', name: 'Türkisch'),
  AppLanguage(code: 'ur', name: 'Urdu'),
];

const List<Locale> supportedAppLocales = <Locale>[
  Locale('ar'),
  Locale('bn'),
  Locale('de'),
  Locale('en'),
  Locale('fr'),
  Locale('ha'),
  Locale('id'),
  Locale('jv'),
  Locale('ms'),
  Locale('nl'),
  Locale('ps'),
  Locale('fa'),
  Locale('ru'),
  Locale('so'),
  Locale('sw'),
  Locale('ce'),
  Locale('tr'),
  Locale('ur'),
];

String languageName(String code) {
  if (code == 'ms') return 'Indonesisch / Malaiisch';
  for (final AppLanguage language in appLanguages) {
    if (language.code == code) return language.name;
  }
  return code;
}
