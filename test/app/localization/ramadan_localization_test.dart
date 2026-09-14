import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/localization/ramadan_translations.dart';

void main() {
  for (final Locale locale in AppStrings.supportedLocales) {
    test('${locale.languageCode} has complete Ramadan translations', () {
      final Map<String, String> translations =
          AppStrings.translations[locale.languageCode]!;
      final RegExp parameter = RegExp(r'\{\w+\}');
      for (final MapEntry<String, String> source
          in ramadanEnTranslations.entries) {
        final String? target = translations[source.key];
        expect(target?.trim(), isNotEmpty, reason: source.key);
        expect(
          parameter.allMatches(target!).map((match) => match.group(0)).toSet(),
          parameter
              .allMatches(source.value)
              .map((match) => match.group(0))
              .toSet(),
          reason: '${locale.languageCode}/${source.key}',
        );
      }

      final AppStrings strings = AppStrings(locale);
      expect(
        strings.t(
          'ramadanDay',
          params: <String, String>{'day': strings.number(12)},
        ),
        isNot(contains(RegExp(r'\{\w+\}'))),
      );
      expect(
        strings.t(
          'suhurReminderBody',
          params: <String, String>{'minutes': strings.number(30)},
        ),
        isNot(contains(RegExp(r'\{\w+\}'))),
      );
    });
  }
}
