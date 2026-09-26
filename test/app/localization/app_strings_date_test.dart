import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/localization/localized_date_data.dart';
import 'package:salah_focus/app/localization/manual_location_translations.dart';
import 'package:salah_focus/app/localization/privacy_legal_translations.dart';
import 'package:salah_focus/app/localization/report_problem_translations.dart';
import 'package:salah_focus/core/theme/app_theme.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test(
    'clock formatting follows the supplied system 12/24-hour preference',
    () {
      final AppStrings strings = AppStrings(const Locale('en'));
      final DateTime instant = DateTime(2026, 9, 18, 13, 30);
      expect(strings.time(instant, use24HourFormat: true), '13:30');
      expect(
        strings.time(instant, use24HourFormat: false).replaceAll('\u202f', ' '),
        '1:30 PM',
      );
      expect(instant.hour, 13);
      expect(instant.minute, 30);
    },
  );

  const Map<String, String> gregorianExamples = <String, String>{
    'ar': 'الاثنين، ٢١ سبتمبر ٢٠٢٦',
    'bn': 'সোমবার, ২১ সেপ্টেম্বর ২০২৬',
    'de': 'Montag, 21. September 2026',
    'en': 'Monday, 21 September 2026',
    'es': 'lunes, 21 de septiembre de 2026',
    'fa': 'دوشنبه، ۲۱ سپتامبر ۲۰۲۶',
    'fr': 'lundi 21 septembre 2026',
    'id': 'Senin, 21 September 2026',
    'ms': 'Isnin, 21 September 2026',
    'pa': 'سوموار، ۲۱ ستمبر ۲۰۲۶',
    'ps': 'دونۍ، ۲۱ سېپتمبر ۲۰۲۶',
    'tr': '21 Eylül 2026 Pazartesi',
    'ur': 'پیر، ۲۱ ستمبر ۲۰۲۶',
  };

  const Map<String, String> hijriExamples = <String, String>{
    'ar': '٧ ربيع الآخر ١٤٤٨',
    'bn': '৭ রবিউস সানি ১৪৪৮',
    'de': '7 Rabi al-Thani 1448',
    'en': '7 Rabi al-Thani 1448',
    'es': '7 Rabi al-Thani 1448',
    'fa': '۷ ربیع‌الثانی ۱۴۴۸',
    'fr': '7 Rabia ath-Thani 1448',
    'id': '7 Rabiulakhir 1448',
    'ms': '7 Rabiulakhir 1448',
    'pa': '۷ ربیع الثانی ۱۴۴۸',
    'ps': '۷ ربیع الثاني ۱۴۴۸',
    'tr': '7 Rebiülahir 1448',
    'ur': '۷ ربیع الثانی ۱۴۴۸',
  };

  for (final MapEntry<String, String> example in gregorianExamples.entries) {
    test('${example.key} renders a fully localized Gregorian date', () {
      final AppStrings strings = AppStrings(Locale(example.key));
      expect(strings.fullDate(DateTime(2026, 9, 21)), example.value);
    });
  }

  for (final MapEntry<String, String> example in hijriExamples.entries) {
    test('${example.key} renders a natural localized Hijri date', () {
      final AppStrings strings = AppStrings(Locale(example.key));
      expect(
        strings.hijriDate(
          '7 Rabīʿ al-thānī 1448',
          day: 7,
          month: 4,
          year: 1448,
        ),
        example.value,
      );
      expect(strings.hijriDate('7 Rabīʿ al-thānī 1448'), example.value);
    });
  }

  test('native numeral systems are used consistently', () {
    expect(AppStrings(const Locale('ar')).number(2026), '٢٬٠٢٦');
    expect(AppStrings(const Locale('ar')).number(12.5), '١٢٫٥');
    expect(AppStrings(const Locale('fa')).number(2026), '۲٬۰۲۶');
    expect(AppStrings(const Locale('ur')).number(2), '۲');
    expect(AppStrings(const Locale('ps')).number(5), '۵');
    expect(AppStrings(const Locale('pa')).number(25), '۲۵');
    expect(AppStrings(const Locale('bn')).number(2026), '২,০২৬');
  });

  test('native date data is stored as literal valid UTF-8', () async {
    final List<int> bytes = await File(
      'lib/app/localization/localized_date_data.dart',
    ).readAsBytes();
    final String source = utf8.decode(bytes, allowMalformed: false);

    for (final String literal in <String>[
      'محرم',
      'ربيع الآخر',
      'ذو الحجة',
      'ربیع‌الثانی',
      'ذی‌الحجه',
      'ربیع الثانی',
      'سوموار',
      'ربیع الثاني',
      'মুহাররম',
      'রবিউস সানি',
    ]) {
      expect(source, contains(literal), reason: literal);
    }
    expect(source, isNot(contains('Arabic:')));
    expect(source, isNot(contains('Persian:')));
    expect(source, isNot(contains('Urdu:')));
    expect(source, isNot(contains('Pashto:')));
    expect(source, isNot(contains('Bengali:')));
  });

  test('all Hijri calendars contain twelve non-empty native month names', () {
    expect(localizedHijriMonths.keys, containsAll(gregorianExamples.keys));
    for (final MapEntry<String, List<String>> locale
        in localizedHijriMonths.entries) {
      expect(locale.value, hasLength(12), reason: locale.key);
      expect(
        locale.value.every((String month) => month.trim().isNotEmpty),
        isTrue,
        reason: locale.key,
      );
    }
  });

  test('Latin locales retain the original platform typography', () {
    final ThemeData originalLight = AppTheme.light();
    final ThemeData originalDark = AppTheme.dark();
    for (final String languageCode in <String>[
      'de',
      'en',
      'es',
      'fr',
      'id',
      'ms',
      'tr',
    ]) {
      final List<(ThemeData, ThemeData)> themes = <(ThemeData, ThemeData)>[
        (AppTheme.light(languageCode: languageCode), originalLight),
        (AppTheme.dark(languageCode: languageCode), originalDark),
      ];
      for (final (ThemeData theme, ThemeData original) in themes) {
        expect(
          theme.textTheme.bodyMedium?.fontFamily,
          original.textTheme.bodyMedium?.fontFamily,
        );
        expect(theme.textTheme.bodyMedium?.fontFamilyFallback, isNull);
      }
    }
  });

  /*test('native-script locales retain targeted font fallbacks', () {
    for (final String languageCode in <String>['ar', 'fa', 'pa', 'ps', 'ur']) {
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light(languageCode: languageCode),
        AppTheme.dark(languageCode: languageCode),
      ]) {
        final List<String>? fallbacks =
            theme.textTheme.bodyMedium?.fontFamilyFallback;
        expect(fallbacks, contains('Noto Sans Arabic'));
        expect(fallbacks, contains('Noto Nastaliq Urdu'));
        expect(fallbacks, contains('Nirmala UI'));
        expect(fallbacks, isNot(contains('Noto Sans Bengali')));
      }
    }

    for (final ThemeData theme in <ThemeData>[
      AppTheme.light(languageCode: 'bn'),
      AppTheme.dark(languageCode: 'bn'),
    ]) {
      final List<String>? fallbacks =
          theme.textTheme.bodyMedium?.fontFamilyFallback;
      expect(fallbacks, contains('Noto Sans Bengali'));
      expect(fallbacks, contains('Nirmala UI'));
      expect(fallbacks, isNot(contains('Noto Sans Arabic')));
    }
  });
*/
  test('native-script locales retain targeted font fallbacks', () {
    for (final ThemeData theme in <ThemeData>[
      AppTheme.light(languageCode: 'ar'),
      AppTheme.dark(languageCode: 'ar'),
    ]) {
      final List<String>? fallbacks =
          theme.textTheme.bodyMedium?.fontFamilyFallback;
      expect(fallbacks, contains('Noto Sans Arabic'));
      expect(fallbacks, contains('Geeza Pro'));
      expect(fallbacks, contains('Noto Naskh Arabic'));
      expect(fallbacks, isNot(contains('Noto Nastaliq Urdu')));
      expect(fallbacks, isNot(contains('Noto Sans Bengali')));
    }

    for (final String languageCode in <String>['fa', 'pa', 'ps', 'ur']) {
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light(languageCode: languageCode),
        AppTheme.dark(languageCode: languageCode),
      ]) {
        final List<String>? fallbacks =
            theme.textTheme.bodyMedium?.fontFamilyFallback;
        expect(fallbacks, contains('Noto Sans Arabic'));
        expect(fallbacks, contains('Noto Nastaliq Urdu'));
        expect(fallbacks, contains('Nirmala UI'));
        expect(fallbacks, isNot(contains('Noto Sans Bengali')));
      }
    }

    for (final ThemeData theme in <ThemeData>[
      AppTheme.light(languageCode: 'bn'),
      AppTheme.dark(languageCode: 'bn'),
    ]) {
      final List<String>? fallbacks =
          theme.textTheme.bodyMedium?.fontFamilyFallback;
      expect(fallbacks, contains('Noto Sans Bengali'));
      expect(fallbacks, contains('Nirmala UI'));
      expect(fallbacks, isNot(contains('Noto Sans Arabic')));
    }
  });

  test('native-script catalogs contain no Latin-only prose fallbacks', () {
    const Map<String, String> scripts = <String, String>{
      'ar': r'[\u0600-\u06ff]',
      'fa': r'[\u0600-\u06ff]',
      'pa': r'[\u0600-\u06ff]',
      'ps': r'[\u0600-\u06ff]',
      'ur': r'[\u0600-\u06ff]',
      'bn': r'[\u0980-\u09ff]',
    };
    final RegExp prose = RegExp(r'[A-Za-zÄÖÜäöüß]{4,}');

    for (final MapEntry<String, String> locale in scripts.entries) {
      final RegExp nativeScript = RegExp(locale.value);
      final List<Map<String, String>> catalogs = <Map<String, String>>[
        AppStrings.translations[locale.key]!,
        manualLocationTranslations[locale.key]!,
        privacyLegalUiTranslations[locale.key]!,
        reportProblemTranslations[locale.key]!,
      ];
      for (final Map<String, String> catalog in catalogs) {
        for (final MapEntry<String, String> value in catalog.entries) {
          if (<String>{'appName', 'linkedin'}.contains(value.key)) continue;
          expect(
            prose.hasMatch(value.value) && !nativeScript.hasMatch(value.value),
            isFalse,
            reason: '${locale.key}/${value.key}: ${value.value}',
          );
        }
      }
    }
  });
}
