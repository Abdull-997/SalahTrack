import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/prayer_times/domain/friday_prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/presentation/home_screen.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';

class _Clock implements ClockService {
  const _Clock(this.now);

  final DateTime now;

  @override
  DateTime nowUtc() => now;
}

PrayerDay _day(String date) => PrayerDay(
  localDate: date,
  timezoneId: 'UTC',
  entries: <PrayerEntry>[
    for (final PrayerType type in PrayerType.values)
      PrayerEntry(
        id: '$date-${type.name}',
        localDate: date,
        type: type,
        scheduledAtUtc: DateTime.parse(
          '${date}T${<String>['05:42', '13:28', '16:51', '19:14', '20:42'][type.index]}:00Z',
        ),
        timezoneId: 'UTC',
        graceEndsAtUtc: DateTime.parse('${date}T23:00:00Z'),
        trackingEndsAtUtc: DateTime.parse('${date}T23:30:00Z'),
        status: PrayerStatus.upcoming,
      ),
  ],
);

Widget _app({
  required String date,
  required bool enabled,
  Locale locale = const Locale('en'),
  ThemeData? theme,
  bool use24HourFormat = true,
}) => ProviderScope(
  overrides: [
    initialPreferencesProvider.overrideWithValue(
      AppPreferences(
        prayerSettings: PrayerSettings(
          fridayPrayer: FridayPrayerSettings(enabled: enabled),
        ),
        localeCode: locale.languageCode,
        themeMode: theme?.brightness == Brightness.dark ? 'dark' : 'light',
        onboardingComplete: true,
      ),
    ),
    clockServiceProvider.overrideWithValue(
      _Clock(DateTime.parse('${date}T08:00:00Z')),
    ),
    todayPrayerDayProvider.overrideWith((Ref ref) async => _day(date)),
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
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(alwaysUse24HourFormat: use24HourFormat),
      child: child!,
    ),
    home: const Scaffold(body: HomeScreen()),
  ),
);

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('enabled Friday Prayer appears between Dhuhr and Asr on Friday', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(date: '2026-09-18', enabled: true));
    await tester.pumpAndSettle();

    expect(find.text("Friday Prayer / Jumu'ah"), findsOneWidget);
    expect(find.text('Reminder only · no confirmation'), findsOneWidget);
    // Automatic mode deliberately mirrors the Friday Dhuhr entry.
    expect(find.text('13:28'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Dhuhr')).dy,
      lessThan(tester.getTopLeft(find.text("Friday Prayer / Jumu'ah")).dy),
    );
    expect(
      tester.getTopLeft(find.text("Friday Prayer / Jumu'ah")).dy,
      lessThan(tester.getTopLeft(find.text('Asr')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Friday Prayer is absent when disabled or when it is not Friday',
    (WidgetTester tester) async {
      await tester.pumpWidget(_app(date: '2026-09-18', enabled: false));
      await tester.pumpAndSettle();
      expect(find.text("Friday Prayer / Jumu'ah"), findsNothing);

      await tester.pumpWidget(_app(date: '2026-09-19', enabled: true));
      await tester.pumpAndSettle();
      expect(find.text("Friday Prayer / Jumu'ah"), findsNothing);
    },
  );

  testWidgets('Home and Friday Prayer use the system 12-hour format', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(date: '2026-09-18', enabled: true, use24HourFormat: false),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1:28'), findsNWidgets(2));
    expect(find.textContaining('PM'), findsWidgets);
  });

  testWidgets('Friday Prayer tile fits RTL and dark mode on a narrow screen', (
    WidgetTester tester,
  ) async {
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
        date: '2026-09-18',
        enabled: true,
        locale: const Locale('ar'),
        theme: AppTheme.dark(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('صلاة الجمعة'), 250);

    expect(find.text('صلاة الجمعة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('صلاة الجمعة'))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
