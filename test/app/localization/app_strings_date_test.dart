import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/localization/app_strings.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('Arabic Gregorian dates use Levantine month names', () {
    final AppStrings strings = AppStrings(const Locale('ar'));

    final String date = strings.date(
      DateTime(2026, 9, 7),
      pattern: 'EEEE, d MMMM y',
    );

    expect(date, contains('أيلول'));
    expect(date, isNot(contains('سبتمبر')));
    expect(date, contains('الاثنين'));
  });

  for (final String localeCode in <String>['ar', 'ur', 'ps']) {
    test('$localeCode Hijri dates use shared Arabic month names', () {
      final AppStrings strings = AppStrings(Locale(localeCode));
      final String date = strings.hijriDate('7 Rabīʿ al-awwal 1448');

      expect(date, contains('ربيع الأول'));
      expect(date, isNot(contains('Rab')));
    });
  }

  test('German dates retain their localized Gregorian month names', () {
    final AppStrings strings = AppStrings(const Locale('de'));

    expect(
      strings.date(DateTime(2026, 9, 7), pattern: 'd MMMM y'),
      contains('September'),
    );
  });
}
