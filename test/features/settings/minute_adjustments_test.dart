import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

const Map<PrayerType, (int, int)> _times = <PrayerType, (int, int)>{
  PrayerType.fajr: (5, 42),
  PrayerType.dhuhr: (13, 28),
  PrayerType.asr: (16, 51),
  PrayerType.maghrib: (19, 14),
  PrayerType.isha: (20, 42),
};

PrayerDay _prayerDay({int fajrAdjustment = 0}) {
  final List<PrayerEntry> entries = <PrayerEntry>[];
  for (final PrayerType type in PrayerType.values) {
    final (int hour, int minute) = _times[type]!;
    final int adjustment = type == PrayerType.fajr ? fajrAdjustment : 0;
    final DateTime scheduled = DateTime.utc(
      2026,
      9,
      14,
      hour,
      minute + adjustment,
    );
    entries.add(
      PrayerEntry(
        id: '2026-09-14-${type.name}',
        localDate: '2026-09-14',
        type: type,
        scheduledAtUtc: scheduled,
        timezoneId: 'UTC',
        graceEndsAtUtc: scheduled.add(const Duration(hours: 1)),
        trackingEndsAtUtc: scheduled.add(const Duration(hours: 2)),
        status: PrayerStatus.upcoming,
        manualOffsetMinutes: adjustment,
      ),
    );
  }
  return PrayerDay(
    localDate: '2026-09-14',
    timezoneId: 'UTC',
    entries: entries,
  );
}

Widget _app({
  required Locale locale,
  required PrayerDay? day,
  PrayerSettings settings = const PrayerSettings(),
  ThemeData? theme,
  bool prayerTimesFail = false,
}) => ProviderScope(
  overrides: [
    initialPreferencesProvider.overrideWithValue(
      AppPreferences(
        prayerSettings: settings,
        localeCode: locale.languageCode,
        themeMode: theme?.brightness == Brightness.dark ? 'dark' : 'light',
        onboardingComplete: true,
      ),
    ),
    todayPrayerDayProvider.overrideWith((Ref ref) async {
      if (prayerTimesFail) throw StateError('Prayer times failed to load.');
      return day;
    }),
  ],
  child: MaterialApp(
    theme: theme ?? AppTheme.light(),
    locale: locale,
    supportedLocales: AppStrings.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      AppStrings.cupertinoFallbackDelegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (BuildContext context, Widget? child) => Directionality(
      textDirection: textDirectionForLanguage(locale.languageCode),
      child: child ?? const SizedBox.shrink(),
    ),
    home: const SettingsScreen(),
  ),
);

Future<void> _openAdjustments(WidgetTester tester, Locale locale) async {
  final Finder row = find
      .text(AppStrings(locale).t('manualAdjustments'))
      .hitTestable();
  await tester.scrollUntilVisible(row, 250);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
}

String _textAtKey(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting();
  });
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  for (final Locale locale in AppStrings.supportedLocales) {
    testWidgets(
      '${locale.languageCode} shows real prayer times and a live adjustment preview',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
        );
        await tester.pumpWidget(
          _app(
            locale: locale,
            day: _prayerDay(),
            theme: locale.languageCode == 'ur'
                ? AppTheme.dark()
                : AppTheme.light(),
          ),
        );
        await tester.pumpAndSettle();
        await _openAdjustments(tester, locale);

        final AppStrings strings = AppStrings(locale);
        final Finder dialogList = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Scrollable),
        );
        for (final PrayerType type in PrayerType.values) {
          final Finder time = find.byKey(
            ValueKey<String>('adjustment-time-${type.name}'),
          );
          await tester.scrollUntilVisible(time, 100, scrollable: dialogList);
          final (int hour, int minute) = _times[type]!;
          expect(
            _textAtKey(tester, 'adjustment-time-${type.name}'),
            strings.time(DateTime.utc(2026, 9, 14, hour, minute)),
          );
          if (type != PrayerType.fajr) continue;
          final Finder plus = find.byKey(
            const ValueKey<String>('adjustment-plus-fajr'),
          );
          await Scrollable.ensureVisible(tester.element(plus), alignment: 0.5);
          await tester.pumpAndSettle();
          expect(plus.hitTestable(), findsOneWidget);
          expect(tester.getSize(plus).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(plus).height, greaterThanOrEqualTo(48));
          await tester.tap(plus);
          await tester.pump();
          expect(
            _textAtKey(tester, 'adjustment-time-fajr'),
            strings.time(DateTime.utc(2026, 9, 14, 5, 43)),
          );
          expect(
            _textAtKey(tester, 'adjustment-value-fajr'),
            strings.minutes(1),
          );
        }
        final TextDirection expectedDirection = textDirectionForLanguage(
          locale.languageCode,
        );
        expect(
          Directionality.of(tester.element(find.byType(AlertDialog))),
          expectedDirection,
        );
        expect(find.text(strings.t('cancel')).hitTestable(), findsOneWidget);
        expect(find.text(strings.t('save')).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('an existing correction is not applied twice in the preview', (
    WidgetTester tester,
  ) async {
    const PrayerSettings settings = PrayerSettings(
      adjustments: <PrayerType, int>{PrayerType.fajr: 5},
    );
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        day: _prayerDay(fajrAdjustment: 5),
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();
    await _openAdjustments(tester, const Locale('en'));

    final Finder dialogList = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('adjustment-time-fajr')),
      100,
      scrollable: dialogList,
    );
    expect(_textAtKey(tester, 'adjustment-time-fajr'), '05:47');
    await tester.tap(
      find.byKey(const ValueKey<String>('adjustment-plus-fajr')),
    );
    await tester.pump();
    expect(_textAtKey(tester, 'adjustment-time-fajr'), '05:48');
    expect(_textAtKey(tester, 'adjustment-value-fajr'), '6 min');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing prayer data shows a fallback and keeps controls usable',
    (WidgetTester tester) async {
      const Locale locale = Locale('en');
      await tester.pumpWidget(
        _app(locale: locale, day: null, prayerTimesFail: true),
      );
      await tester.pumpAndSettle();
      await _openAdjustments(tester, locale);

      final AppStrings strings = AppStrings(locale);
      expect(find.text(strings.t('noData')), findsOneWidget);
      final Finder dialogList = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Scrollable),
      );
      for (final PrayerType type in PrayerType.values) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey<String>('adjustment-time-${type.name}')),
          100,
          scrollable: dialogList,
        );
        expect(_textAtKey(tester, 'adjustment-time-${type.name}'), '—');
        if (type != PrayerType.fajr) continue;
        await tester.tap(
          find.byKey(const ValueKey<String>('adjustment-plus-fajr')),
        );
        await tester.pump();
        expect(_textAtKey(tester, 'adjustment-time-fajr'), '—');
        expect(_textAtKey(tester, 'adjustment-value-fajr'), '1 min');
      }
      expect(tester.takeException(), isNull);
    },
  );
}
