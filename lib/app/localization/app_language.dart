import 'package:flutter/material.dart';

/// A language supported by the app, shown using its native display name.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    this.isRtl = false,
  });

  final String code;
  final String name;
  final bool isRtl;

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;
}

/// Only languages with a complete in-app translation are selectable.
///
/// Display names use each language's own name, so the picker remains useful
/// regardless of the language currently active in the app.
const List<AppLanguage> appLanguages = <AppLanguage>[
  AppLanguage(code: 'ar', name: 'العربية', isRtl: true),
  AppLanguage(code: 'bn', name: 'বাংলা'),
  AppLanguage(code: 'de', name: 'Deutsch'),
  AppLanguage(code: 'en', name: 'English'),
  AppLanguage(code: 'es', name: 'Español'),
  AppLanguage(code: 'fa', name: 'فارسی', isRtl: true),
  AppLanguage(code: 'fr', name: 'Français'),
  AppLanguage(code: 'id', name: 'Bahasa Indonesia'),
  AppLanguage(code: 'ms', name: 'Bahasa Melayu'),
  AppLanguage(code: 'pa', name: 'پنجابی', isRtl: true),
  AppLanguage(code: 'ps', name: 'پښتو', isRtl: true),
  AppLanguage(code: 'tr', name: 'Türkçe'),
  AppLanguage(code: 'ur', name: 'اردو', isRtl: true),
];

const List<Locale> supportedAppLocales = <Locale>[
  Locale('ar'),
  Locale('bn'),
  Locale('de'),
  Locale('en'),
  Locale('es'),
  Locale('fa'),
  Locale('fr'),
  Locale('id'),
  Locale('ms'),
  Locale.fromSubtags(languageCode: 'pa', scriptCode: 'Arab'),
  Locale('ps'),
  Locale('tr'),
  Locale('ur'),
];

Locale appLocaleFor(String code) => code == 'pa'
    ? const Locale.fromSubtags(languageCode: 'pa', scriptCode: 'Arab')
    : Locale(code);

TextDirection textDirectionForLanguage(String code) {
  for (final AppLanguage language in appLanguages) {
    if (language.code == code) return language.textDirection;
  }
  return TextDirection.ltr;
}

String languageName(String code) {
  for (final AppLanguage language in appLanguages) {
    if (language.code == code) return language.name;
  }
  return code;
}
