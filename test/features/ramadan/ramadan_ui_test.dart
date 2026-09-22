import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/core/review/app_review_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/presentation/home_screen.dart';
import 'package:salah_focus/features/ramadan/application/ramadan_providers.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_calendar.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_goal.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_record.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_settings.dart';
import 'package:salah_focus/features/ramadan/presentation/ramadan_tracker_section.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Clock implements ClockService {
  const _Clock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

class _Reviews implements AppReviewService {
  int requests = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => requests++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('outside Ramadan keeps Home unchanged when master is on', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.utc(2026, 9, 14, 12);
    final PrayerDay day = _day(now, ramadan: false);
    await tester.pumpWidget(
      _homeApp(
        day: day,
        now: now,
        settings: const RamadanSettings(enabled: true),
        ramadanData: null,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('ramadan-home-card')),
      findsNothing,
    );
    expect(
      find.text(AppStrings(const Locale('en')).t('nextPrayer')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('master switch off hides active Ramadan Home UI', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.utc(2027, 2, 19, 12);
    final PrayerDay day = _day(now, ramadan: true);
    await tester.pumpWidget(
      _homeApp(
        day: day,
        now: now,
        settings: const RamadanSettings(enabled: false),
        ramadanData: _todayData(day),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('ramadan-home-card')),
      findsNothing,
    );
    expect(
      find.text(AppStrings(const Locale('en')).t('today')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Ramadan Home uses Fajr and Maghrib and keeps prayer count at five',
    (WidgetTester tester) async {
      final DateTime now = DateTime.utc(2027, 2, 19, 12);
      final PrayerDay day = _day(now, ramadan: true);
      final RamadanTodayData data = _todayData(
        day,
        record: const RamadanRecord(
          localDate: '2027-02-19',
          hijriYear: 1448,
          hijriDay: 12,
          fastingStatus: FastingStatus.fasted,
          tarawihCompleted: true,
        ),
      );
      await tester.pumpWidget(
        _homeApp(
          day: day,
          now: now,
          settings: const RamadanSettings(),
          ramadanData: data,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('ramadan-home-card')),
        findsOneWidget,
      );
      expect(find.text('Ends at 05:17'), findsOneWidget);
      expect(find.text('At 19:42'), findsOneWidget);
      expect(find.textContaining('4/5'), findsOneWidget);
      expect(find.textContaining('Tarawih: Completed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ramadan Home fits a small dark RTL screen', (
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
    final DateTime now = DateTime.utc(2027, 2, 19, 20);
    final PrayerDay day = _day(now, ramadan: true);
    await tester.pumpWidget(
      _homeApp(
        day: day,
        now: now,
        locale: const Locale('ar'),
        dark: true,
        settings: const RamadanSettings(qiyamTrackingEnabled: true),
        ramadanData: _todayData(day),
      ),
    );
    await tester.pumpAndSettle();

    final Finder card = find.byKey(const ValueKey<String>('ramadan-home-card'));
    await tester.scrollUntilVisible(
      card,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(card, findsOneWidget);
    expect(Directionality.of(tester.element(card)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Ramadan tracker shows 30 accessible states and editable history',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final DateTime now = DateTime.utc(2027, 2, 19, 12);
      final PrayerDay day = _day(now, ramadan: true);
      final RamadanTodayData today = _todayData(day);
      final RamadanTrackerData tracker = RamadanTrackerData(
        today: today,
        records: const <RamadanRecord>[
          RamadanRecord(
            localDate: '2027-02-18',
            hijriYear: 1448,
            hijriDay: 11,
            fastingStatus: FastingStatus.didNotFast,
          ),
        ],
        goals: const <RamadanGoal>[
          RamadanGoal(id: 'quran', title: 'Read Quran'),
        ],
        completedGoalIds: const <String>{},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialPreferencesProvider.overrideWithValue(
              const AppPreferences(
                prayerSettings: PrayerSettings(),
                localeCode: 'en',
                themeMode: 'dark',
                onboardingComplete: true,
                ramadanSettings: RamadanSettings(qiyamTrackingEnabled: true),
              ),
            ),
            ramadanTrackerDataProvider.overrideWith((ref) async => tracker),
          ],
          child: _localizedApp(
            locale: const Locale('en'),
            dark: true,
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: RamadanTrackerSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('ramadan-day-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('ramadan-day-30')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('ramadan-day-11')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('ramadan-day-11')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Did not fast'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ramadan Settings remain visible and disable child options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialPreferencesProvider.overrideWithValue(
            const AppPreferences(
              prayerSettings: PrayerSettings(),
              localeCode: 'en',
              themeMode: 'system',
              onboardingComplete: true,
              ramadanSettings: RamadanSettings(enabled: false),
            ),
          ),
        ],
        child: _localizedApp(
          locale: const Locale('en'),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder master = find.byKey(
      const ValueKey<String>('ramadan-features-enabled'),
    );
    await tester.scrollUntilVisible(master, 300);
    expect(master, findsOneWidget);
    final SwitchListTile suhur = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey<String>('suhur-reminder-enabled')),
    );
    final SwitchListTile iftar = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey<String>('iftar-reminder-enabled')),
    );
    expect(suhur.onChanged, isNull);
    expect(iftar.onChanged, isNull);
    expect(
      find.byKey(const ValueKey<String>('suhur-reminder-time')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'review waits three days and a calm Home return, then asks once',
    (WidgetTester tester) async {
      final DateTime now = DateTime.utc(2027, 2, 19, 12);
      final PrayerDay day = _day(now, ramadan: false);
      final ValueNotifier<bool> homeVisible = ValueNotifier<bool>(true);
      final _Reviews reviews = _Reviews();
      addTearDown(homeVisible.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialPreferencesProvider.overrideWithValue(
              AppPreferences(
                prayerSettings: const PrayerSettings(),
                localeCode: 'en',
                themeMode: 'light',
                onboardingComplete: true,
                ramadanSettings: const RamadanSettings(enabled: false),
                firstLaunchAtUtc: now.subtract(const Duration(days: 4)),
              ),
            ),
            clockServiceProvider.overrideWithValue(_Clock(now)),
            appReviewServiceProvider.overrideWithValue(reviews),
            todayPrayerDayProvider.overrideWith((ref) async => day),
          ],
          child: _localizedApp(
            locale: const Locale('en'),
            home: ValueListenableBuilder<bool>(
              valueListenable: homeVisible,
              builder: (BuildContext context, bool visible, Widget? child) =>
                  TickerMode(enabled: visible, child: child!),
              child: const Scaffold(body: SafeArea(child: HomeScreen())),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(
        reviews.requests,
        0,
        reason: 'Never ask on the initial Home visit.',
      );

      homeVisible.value = false;
      await tester.pump();
      homeVisible.value = true;
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(reviews.requests, 1);

      homeVisible.value = false;
      await tester.pump();
      homeVisible.value = true;
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(reviews.requests, 1);
    },
  );

  testWidgets('review never interrupts an active prayer reminder state', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.utc(2027, 2, 19, 12);
    final PrayerDay base = _day(now, ramadan: false);
    final PrayerDay day = base.copyWith(
      entries: <PrayerEntry>[
        base.entries.first.copyWith(status: PrayerStatus.active),
        ...base.entries.skip(1),
      ],
    );
    final ValueNotifier<bool> homeVisible = ValueNotifier<bool>(true);
    final _Reviews reviews = _Reviews();
    addTearDown(homeVisible.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialPreferencesProvider.overrideWithValue(
            AppPreferences(
              prayerSettings: const PrayerSettings(),
              localeCode: 'en',
              themeMode: 'light',
              onboardingComplete: true,
              firstLaunchAtUtc: now.subtract(const Duration(days: 4)),
            ),
          ),
          clockServiceProvider.overrideWithValue(_Clock(now)),
          appReviewServiceProvider.overrideWithValue(reviews),
          todayPrayerDayProvider.overrideWith((ref) async => day),
        ],
        child: _localizedApp(
          locale: const Locale('en'),
          home: ValueListenableBuilder<bool>(
            valueListenable: homeVisible,
            builder: (BuildContext context, bool visible, Widget? child) =>
                TickerMode(enabled: visible, child: child!),
            child: const Scaffold(body: SafeArea(child: HomeScreen())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    homeVisible.value = false;
    await tester.pump();
    homeVisible.value = true;
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(reviews.requests, 0);
  });
}

Widget _homeApp({
  required PrayerDay day,
  required DateTime now,
  required RamadanSettings settings,
  required RamadanTodayData? ramadanData,
  Locale locale = const Locale('en'),
  bool dark = false,
}) => ProviderScope(
  overrides: [
    initialPreferencesProvider.overrideWithValue(
      AppPreferences(
        prayerSettings: const PrayerSettings(),
        localeCode: locale.languageCode,
        themeMode: dark ? 'dark' : 'light',
        onboardingComplete: true,
        ramadanSettings: settings,
      ),
    ),
    clockServiceProvider.overrideWithValue(_Clock(now)),
    todayPrayerDayProvider.overrideWith((ref) async => day),
    ramadanTodayProvider.overrideWith((ref) async => ramadanData),
  ],
  child: _localizedApp(
    locale: locale,
    dark: dark,
    home: const Scaffold(body: SafeArea(child: HomeScreen())),
  ),
);

Widget _localizedApp({
  required Locale locale,
  required Widget home,
  bool dark = false,
}) => MaterialApp(
  theme: dark ? AppTheme.dark() : AppTheme.light(),
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
    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
    child: child!,
  ),
  home: home,
);

RamadanTodayData _todayData(PrayerDay day, {RamadanRecord? record}) =>
    RamadanTodayData(
      prayerDay: day,
      ramadanDate: const RamadanDate(day: 12, year: 1448),
      record:
          record ??
          const RamadanRecord(
            localDate: '2027-02-19',
            hijriYear: 1448,
            hijriDay: 12,
          ),
      goals: const <RamadanGoal>[RamadanGoal(id: 'quran', title: 'Read Quran')],
      completedGoalIds: const <String>{'quran'},
    );

PrayerDay _day(DateTime _, {required bool ramadan}) {
  const String localDate = '2027-02-19';
  final List<({PrayerType type, int hour, int minute})> times =
      <({PrayerType type, int hour, int minute})>[
        (type: PrayerType.fajr, hour: 5, minute: 17),
        (type: PrayerType.dhuhr, hour: 12, minute: 30),
        (type: PrayerType.asr, hour: 15, minute: 30),
        (type: PrayerType.maghrib, hour: 19, minute: 42),
        (type: PrayerType.isha, hour: 21, minute: 0),
      ];
  return PrayerDay(
    localDate: localDate,
    timezoneId: 'UTC',
    hijriDate: ramadan ? '12 Ramadan 1448' : '2 Shawwal 1448',
    hijriDay: ramadan ? 12 : 2,
    hijriMonth: ramadan ? 9 : 10,
    hijriYear: 1448,
    entries: <PrayerEntry>[
      for (int index = 0; index < times.length; index++)
        PrayerEntry(
          id: '$localDate:${times[index].type.name}',
          localDate: localDate,
          type: times[index].type,
          scheduledAtUtc: DateTime.utc(
            2027,
            2,
            19,
            times[index].hour,
            times[index].minute,
          ),
          timezoneId: 'UTC',
          graceEndsAtUtc: DateTime.utc(
            2027,
            2,
            19,
            times[index].hour,
            times[index].minute + 20,
          ),
          trackingEndsAtUtc: DateTime.utc(
            2027,
            2,
            19,
            times[index].hour + 2,
            times[index].minute,
          ),
          status: index < 4 ? PrayerStatus.prayed : PrayerStatus.upcoming,
        ),
    ],
  );
}
