import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/router/app_router.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/prayer_times/application/prayer_coordinator.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/features/prayer_times/presentation/home_screen.dart';
import 'package:salah_focus/features/prayer_tracker/presentation/tracker_screen.dart';
import 'package:salah_focus/features/qibla/presentation/qibla_screen.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Clock implements ClockService {
  DateTime now = DateTime.utc(2026, 9, 12, 12);

  @override
  DateTime nowUtc() => now;
}

class _Coordinator implements PrayerCoordinator {
  var homeLoads = 0;
  var trackerLoads = 0;
  Completer<PrayerDay?>? pending;

  @override
  Future<PrayerDay?> loadToday({
    required UserLocation location,
    required PrayerSettings settings,
    required String languageCode,
  }) async {
    homeLoads++;
    return pending == null ? _day : await pending!.future;
  }

  @override
  Future<List<PrayerEntry>> entriesBetween(String start, String end) async {
    trackerLoads++;
    return _day.entries;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _preferences = AppPreferences(
  prayerSettings: PrayerSettings(),
  localeCode: 'en',
  themeMode: 'dark',
  onboardingComplete: true,
);

final _day = PrayerDay(
  localDate: '2026-09-12',
  timezoneId: 'UTC',
  entries: [
    for (final type in PrayerType.values)
      PrayerEntry(
        id: '2026-09-12-${type.name}',
        localDate: '2026-09-12',
        type: type,
        scheduledAtUtc: DateTime.utc(2026, 9, 12, 13 + type.index),
        timezoneId: 'UTC',
        graceEndsAtUtc: DateTime.utc(2026, 9, 12, 14 + type.index),
        trackingEndsAtUtc: DateTime.utc(2026, 9, 12, 15 + type.index),
        status: PrayerStatus.upcoming,
      ),
  ],
);

Future<void> _mount(WidgetTester tester, ProviderContainer container) async {
  final router = container.read(goRouterProvider);
  addTearDown(router.dispose);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.dark(),
        locale: const Locale('en'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _switchTab(WidgetTester tester, int index) async {
  await tester.tap(find.byType(NavigationDestination).at(index));
  // Assert the first rendered frame, without waiting for route animations.
  await tester.pump();
  expect(
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
    index,
  );
  const screens = [HomeScreen, TrackerScreen, QiblaScreen, SettingsScreen];
  for (var i = 0; i < screens.length; i++) {
    expect(find.byType(screens[i]), i == index ? findsOneWidget : findsNothing);
  }
}

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'theme changes reuse data and prayer refreshes keep content visible',
    (tester) async {
      final coordinator = _Coordinator();
      final container = ProviderContainer(
        overrides: [
          initialPreferencesProvider.overrideWithValue(
            _preferences.copyWith(
              location: const UserLocation(
                latitude: 0,
                longitude: 0,
                city: '',
                country: '',
                timezoneId: 'UTC',
                isAutomatic: false,
              ),
            ),
          ),
          clockServiceProvider.overrideWithValue(_Clock()),
          prayerCoordinatorProvider.overrideWithValue(coordinator),
        ],
      );
      await _mount(tester, container);
      await _switchTab(tester, 1);
      await tester.pumpAndSettle();
      await _switchTab(tester, 3);
      await container
          .read(settingsControllerProvider.notifier)
          .setThemeMode(ThemeMode.light);
      await _switchTab(tester, 0);
      await tester.pumpAndSettle();
      await _switchTab(tester, 1);
      await tester.pumpAndSettle();
      expect(coordinator.homeLoads, 1);
      expect(coordinator.trackerLoads, 1);

      await _switchTab(tester, 3);
      coordinator.pending = Completer<PrayerDay?>();
      await container
          .read(settingsControllerProvider.notifier)
          .setPrayerSettings(const PrayerSettings(calculationMethodId: 5));
      await _switchTab(tester, 0);
      await tester.pump();
      expect(find.text('Next prayer'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await _switchTab(tester, 1);
      await tester.pump();
      expect(find.text('Prayers confirmed today'), findsOneWidget);
      expect(
        find
            .byType(CircularProgressIndicator)
            .evaluate()
            .where(
              (element) =>
                  (element.widget as CircularProgressIndicator).value == null,
            ),
        isEmpty,
      );
      coordinator.pending!.complete(_day);
      await tester.pumpAndSettle();
      expect(coordinator.homeLoads, 2);
      expect(coordinator.trackerLoads, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('rapid tab changes show one screen and retain state and scroll', (
    tester,
  ) async {
    final clock = _Clock();
    var homeLoads = 0;
    var trackerLoads = 0;
    final container = ProviderContainer(
      overrides: [
        initialPreferencesProvider.overrideWithValue(_preferences),
        clockServiceProvider.overrideWithValue(clock),
        todayPrayerDayProvider.overrideWith((ref) async {
          homeLoads++;
          return _day;
        }),
        trackerDataProvider.overrideWith((ref) async {
          trackerLoads++;
          return TrackerData(entries: _day.entries, localNow: clock.now);
        }),
      ],
    );
    await _mount(tester, container);
    final homeState = tester.state(find.byType(HomeScreen));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    final homeScroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(Scrollable),
      ),
    );
    final homeOffset = homeScroll.position.pixels;
    expect(homeOffset, greaterThan(0));

    await _switchTab(tester, 1);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    final trackerScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(TrackerScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final trackerOffset = trackerScroll.position.pixels;
    expect(trackerOffset, greaterThan(0));

    for (final index in [3, 0, 3, 1, 2, 3, 0, 1, 1, 0]) {
      await _switchTab(tester, index);
      expect(
        find
            .byType(CircularProgressIndicator)
            .evaluate()
            .where(
              (element) =>
                  (element.widget as CircularProgressIndicator).value == null,
            ),
        isEmpty,
      );
    }
    expect(tester.state(find.byType(HomeScreen)), same(homeState));
    expect(homeScroll.position.pixels, homeOffset);
    expect(trackerScroll.position.pixels, trackerOffset);
    await tester.pump(const Duration(seconds: 2));
    expect(homeLoads, 1);
    expect(trackerLoads, 1);

    // Hidden Home must not keep doing timer-driven data work.
    await _switchTab(tester, 3);
    clock.now = clock.now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(minutes: 2));
    expect(homeLoads, 1);
    await _switchTab(tester, 0);
    await tester.pumpAndSettle();
    expect(homeLoads, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pending data never holds Settings over the selected tab', (
    tester,
  ) async {
    final dayResult = Completer<PrayerDay?>();
    final trackerResult = Completer<TrackerData>();
    final container = ProviderContainer(
      overrides: [
        initialPreferencesProvider.overrideWithValue(_preferences),
        clockServiceProvider.overrideWithValue(_Clock()),
        todayPrayerDayProvider.overrideWith((ref) => dayResult.future),
        trackerDataProvider.overrideWith((ref) => trackerResult.future),
      ],
    );
    container.read(goRouterProvider).go('/settings');
    await _mount(tester, container);
    await _switchTab(tester, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await _switchTab(tester, 3);
    await _switchTab(tester, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    dayResult.complete(_day);
    trackerResult.complete(
      TrackerData(entries: _day.entries, localNow: DateTime(2026, 9, 12)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prayers confirmed today'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
