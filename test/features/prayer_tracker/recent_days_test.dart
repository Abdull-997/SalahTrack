import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/prayer_times/application/prayer_coordinator.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/features/prayer_tracker/presentation/tracker_screen.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';

String _iso(DateTime date) => date.toIso8601String().substring(0, 10);

class _Clock implements ClockService {
  _Clock(this.now);
  final DateTime now;
  @override
  DateTime nowUtc() => now;
}

class _Coordinator implements PrayerCoordinator {
  _Coordinator(this.now) {
    for (int offset = -3; offset <= 1; offset++) {
      final DateTime date = DateTime.utc(now.year, now.month, now.day + offset);
      for (final PrayerType type in PrayerType.values) {
        final String day = _iso(date);
        entries.add(
          PrayerEntry(
            id: '$day-${type.name}',
            localDate: day,
            type: type,
            scheduledAtUtc: date,
            timezoneId: 'UTC',
            graceEndsAtUtc: date.add(const Duration(hours: 1)),
            trackingEndsAtUtc: date.add(const Duration(hours: 2)),
            status: PrayerStatus.missed,
          ),
        );
      }
    }
  }
  final DateTime now;
  final List<PrayerEntry> entries = [];
  final List<(String, String)> ranges = [];
  int changes = 0;
  bool fail = false;

  @override
  Future<List<PrayerEntry>> entriesBetween(String start, String end) async {
    ranges.add((start, end));
    return entries
        .where(
          (entry) =>
              entry.localDate.compareTo(start) >= 0 &&
              entry.localDate.compareTo(end) <= 0,
        )
        .toList();
  }

  @override
  Future<PrayerEntry> correctHistoricalPrayer(
    PrayerEntry prayer, {
    required bool prayed,
  }) async {
    if (fail) throw StateError('Save failed');
    changes++;
    final PrayerEntry updated = prayer.copyWith(
      status: prayed ? PrayerStatus.prayed : PrayerStatus.missed,
      editedAtUtc: prayer.localDate.compareTo(_iso(now)) < 0 ? now : null,
    );
    entries[entries.indexWhere((entry) => entry.id == prayer.id)] = updated;
    return updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(
  _Coordinator coordinator,
  DateTime now, {
  Locale locale = const Locale('de'),
}) => ProviderScope(
  overrides: [
    initialPreferencesProvider.overrideWithValue(
      AppPreferences(
        prayerSettings: const PrayerSettings(),
        localeCode: locale.languageCode,
        themeMode: 'dark',
        onboardingComplete: true,
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
    prayerCoordinatorProvider.overrideWithValue(coordinator),
    todayPrayerDayProvider.overrideWith((ref) async => null),
    clockServiceProvider.overrideWithValue(_Clock(now)),
  ],
  child: MaterialApp(
    theme: AppTheme.dark(),
    locale: locale,
    supportedLocales: AppStrings.supportedLocales,
    localizationsDelegates: const [
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
    home: const TrackerScreen(),
  ),
);

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('info button explains every tracker status', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final DateTime now = DateTime.utc(2026, 9, 13, 12);
    await tester.pumpWidget(_app(_Coordinator(now), now));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    final Finder trackerInfo = find.byKey(
      const ValueKey<String>('tracker-info-button'),
    );
    expect(
      find.descendant(of: find.byType(AppBar), matching: trackerInfo),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('tracker-week-heading')),
        matching: trackerInfo,
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(trackerInfo, 200);
    await tester.tap(trackerInfo);
    await tester.pumpAndSettle();

    final AppStrings s = AppStrings(const Locale('de'));
    expect(find.text(s.t('trackerInfoTitle')), findsOneWidget);
    expect(find.text(s.t('trackerInfoIntro')), findsOneWidget);
    for (final PrayerStatus status in PrayerStatus.values) {
      final String name = status.name;
      final String key =
          'status${name[0].toUpperCase()}${name.substring(1)}Help';
      expect(find.text(s.t(key)), findsOneWidget, reason: key);
    }

    await tester.tap(find.text(s.t('close')));
    await tester.pumpAndSettle();
    expect(find.text(s.t('trackerInfoTitle')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('month info explains counts and uses the real calendar colors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final DateTime now = DateTime.utc(2026, 9, 13, 12);
    final _Coordinator coordinator = _Coordinator(now);
    for (int index = 0; index < coordinator.entries.length; index++) {
      final PrayerEntry entry = coordinator.entries[index];
      final PrayerStatus status = switch (entry.localDate) {
        '2026-09-10' => PrayerStatus.prayed,
        '2026-09-11' when entry.type.index < 2 => PrayerStatus.prayed,
        _ => PrayerStatus.missed,
      };
      coordinator.entries[index] = entry.copyWith(status: status);
    }
    await tester.pumpWidget(_app(coordinator, now));
    await tester.pumpAndSettle();

    final Finder monthInfo = find.byKey(
      const ValueKey<String>('month-info-button'),
    );
    await tester.scrollUntilVisible(monthInfo, 300);
    await tester.pumpAndSettle();

    BoxDecoration calendarDecoration(String date) =>
        tester
                .widget<DecoratedBox>(
                  find.byKey(ValueKey<String>('calendar-$date')),
                )
                .decoration
            as BoxDecoration;

    final BoxDecoration complete = calendarDecoration('2026-09-10');
    final BoxDecoration partial = calendarDecoration('2026-09-11');
    final BoxDecoration none = calendarDecoration('2026-09-12');
    final BoxDecoration today = calendarDecoration('2026-09-13');
    final BoxDecoration future = calendarDecoration('2026-09-14');
    expect(today.border, isNotNull);
    expect(future.border, isNull);

    await tester.tap(monthInfo);
    await tester.pumpAndSettle();

    final AppStrings s = AppStrings(const Locale('de'));
    for (final String key in <String>[
      'monthInfoTitle',
      'monthInfoOverview',
      'monthCountHelp',
      'monthAllConfirmedHelp',
      'monthPartiallyConfirmedHelp',
      'monthNoneConfirmedHelp',
      'monthFutureHelp',
      'monthTodayOutlineHelp',
    ]) {
      expect(find.text(s.t(key)), findsOneWidget, reason: key);
    }
    expect(find.text('0/5  ·  1/5  ·  5/5'), findsOneWidget);

    BoxDecoration legendDecoration(String key) =>
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byKey(ValueKey<String>(key)),
                    matching: find.byType(Container),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(legendDecoration('month-legend-complete').color, complete.color);
    expect(legendDecoration('month-legend-partial').color, partial.color);
    expect(legendDecoration('month-legend-none').color, none.color);
    expect(legendDecoration('month-legend-future').color, future.color);
    expect(legendDecoration('month-legend-today').color, today.color);
    expect(legendDecoration('month-legend-today').border, isNotNull);

    await tester.tap(find.text(s.t('close')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final Locale locale in AppStrings.supportedLocales) {
    testWidgets(
      '${locale.languageCode} tracker help is readable on a small screen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
        );
        final DateTime now = DateTime.utc(2026, 9, 13, 12);
        await tester.pumpWidget(_app(_Coordinator(now), now, locale: locale));
        await tester.pumpAndSettle();

        final AppStrings s = AppStrings(locale);
        final TextDirection expectedDirection = textDirectionForLanguage(
          locale.languageCode,
        );
        final Finder trackerInfo = find.byKey(
          const ValueKey<String>('tracker-info-button'),
        );
        await tester.scrollUntilVisible(trackerInfo, 200);
        await tester.pumpAndSettle();
        final Size trackerTouchSize = tester.getSize(trackerInfo);
        expect(trackerTouchSize.width, greaterThanOrEqualTo(48));
        expect(trackerTouchSize.height, greaterThanOrEqualTo(48));
        await tester.tap(trackerInfo);
        await tester.pumpAndSettle();
        expect(find.text(s.t('trackerInfoTitle')), findsOneWidget);
        for (final PrayerStatus status in PrayerStatus.values) {
          final String name = status.name;
          final String key =
              'status${name[0].toUpperCase()}${name.substring(1)}Help';
          expect(find.text(s.t(key)), findsOneWidget, reason: key);
        }
        expect(
          Directionality.of(tester.element(find.byType(AlertDialog))),
          expectedDirection,
        );
        await tester.tap(find.text(s.t('close')).hitTestable());
        await tester.pumpAndSettle();

        final Finder infoButton = find.byKey(
          const ValueKey<String>('month-info-button'),
        );
        await tester.scrollUntilVisible(infoButton, 250);
        await tester.pumpAndSettle();
        final Size touchSize = tester.getSize(infoButton);
        expect(touchSize.width, greaterThanOrEqualTo(48));
        expect(touchSize.height, greaterThanOrEqualTo(48));
        await tester.tap(infoButton);
        await tester.pumpAndSettle();

        expect(find.text(s.t('monthInfoTitle')), findsOneWidget);
        expect(find.text(s.t('monthInfoOverview')), findsOneWidget);
        expect(find.text(s.t('monthCountHelp')), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byType(AlertDialog))),
          expectedDirection,
        );
        final Finder close = find.text(s.t('close')).hitTestable();
        expect(close, findsOneWidget);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final DateTime now in [
    DateTime.utc(2027, 1, 1, 12),
    DateTime.utc(2026, 3, 2, 12),
  ]) {
    testWidgets(
      'only three editable days, including previous month on ${_iso(now)}',
      (tester) async {
        tester.view.physicalSize = const Size(430, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final _Coordinator coordinator = _Coordinator(now);
        await tester.pumpWidget(_app(coordinator, now));
        await tester.pumpAndSettle();
        final List<String> expected = List.generate(
          3,
          (offset) => _iso(DateTime(now.year, now.month, now.day - offset)),
        );
        expect(coordinator.ranges.last.$1, expected.last);
        final List<String> keys = tester
            .widgetList(
              find.byWidgetPredicate(
                (widget) =>
                    widget.key is ValueKey<String> &&
                    (widget.key! as ValueKey<String>).value.startsWith(
                      'tracker-day-',
                    ),
              ),
            )
            .map((widget) => (widget.key! as ValueKey<String>).value)
            .toList();
        expect(keys, expected.map((date) => 'tracker-day-$date'));
        expect(find.text('Gestern'), findsOneWidget);
        expect(find.text('Vorgestern'), findsOneWidget);

        final todayHeader = find.byKey(
          ValueKey('tracker-header-${expected.first}'),
        );
        expect(tester.widget<InkWell>(todayHeader).onTap, isNull);
        expect(
          find.byKey(ValueKey('correct-${expected.first}-fajr')),
          findsOneWidget,
        );
        for (final date in expected.skip(1)) {
          expect(find.byKey(ValueKey('correct-$date-fajr')), findsNothing);
          final header = find.byKey(ValueKey('tracker-header-$date'));
          await tester.ensureVisible(header);
          await tester.tap(header);
          await tester.pumpAndSettle();
          expect(find.byKey(ValueKey('correct-$date-fajr')), findsOneWidget);
          await tester.tap(header);
          await tester.pumpAndSettle();
          expect(find.byKey(ValueKey('correct-$date-fajr')), findsNothing);
        }

        for (final String date in expected) {
          if (date != expected.first) {
            final header = find.byKey(ValueKey('tracker-header-$date'));
            await tester.ensureVisible(header);
            await tester.tap(header);
            await tester.pumpAndSettle();
          }
          final Finder edit = find.byKey(ValueKey('correct-$date-fajr'));
          await tester.ensureVisible(edit);
          await tester.tap(edit);
          await tester.pumpAndSettle();
          expect(find.text('Gebet bestätigen?'), findsOneWidget);
          final String localizedDate = AppStrings(const Locale('de'))
              .date(DateTime.parse(date), pattern: 'd MMMM y');
          expect(
            find.text('Fajr am $localizedDate als gebetet markieren?'),
            findsOneWidget,
          );
          expect(
            Theme.of(tester.element(find.byType(AlertDialog))).brightness,
            Brightness.dark,
          );
          final int before = coordinator.changes;
          await tester.tap(find.text('Abbrechen'));
          await tester.pumpAndSettle();
          expect(coordinator.changes, before);
          expect(find.byKey(ValueKey('edited-$date-fajr')), findsNothing);
          await tester.tap(edit);
          await tester.pumpAndSettle();
          // Dismissing the popup must not save either.
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
          expect(coordinator.changes, before);
          await tester.tap(edit);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ich habe gebetet'));
          await tester.pumpAndSettle();
          expect(coordinator.changes, before + 1);
          expect(
            find.byKey(ValueKey('edited-$date-fajr')),
            date == expected.first ? findsNothing : findsOneWidget,
          );
          expect(find.byKey(ValueKey('edited-$date-dhuhr')), findsNothing);
          expect(
            coordinator.entries
                .firstWhere((entry) => entry.id == '$date-fajr')
                .status,
            PrayerStatus.prayed,
          );
          final Finder card = find.byKey(ValueKey('tracker-day-$date'));
          expect(
            find.descendant(of: card, matching: find.text('1/5')),
            findsOneWidget,
          );
        }
        expect(coordinator.changes, 3);
        final Finder todayEdit = find.byKey(
          ValueKey('correct-${expected.first}-fajr'),
        );
        await tester.ensureVisible(todayEdit);
        await tester.tap(todayEdit);
        await tester.pumpAndSettle();
        expect(find.text('Bestätigung zurücknehmen?'), findsOneWidget);
        await tester.tap(find.text('Ja'));
        await tester.pumpAndSettle();
        expect(coordinator.changes, 4);
        // Reverting a past-day correction keeps its edit history visible.
        final pastId = '${expected[1]}-fajr';
        final pastEdit = find.byKey(ValueKey('correct-$pastId'));
        await tester.ensureVisible(pastEdit);
        await tester.tap(pastEdit);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ja'));
        await tester.pumpAndSettle();
        expect(
          coordinator.entries.firstWhere((entry) => entry.id == pastId).status,
          PrayerStatus.missed,
        );
        expect(find.byKey(ValueKey('edited-$pastId')), findsOneWidget);
        expect(
          tester
              .widget<Tooltip>(find.byKey(ValueKey('edited-$pastId')))
              .message,
          'Nachträglich bearbeitet',
        );

        // Recreate the screen to verify markers come from records, not UI state.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(_app(coordinator, now));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('correct-$pastId')), findsNothing);
        final pastHeader = find.byKey(
          ValueKey('tracker-header-${expected[1]}'),
        );
        await tester.ensureVisible(pastHeader);
        await tester.tap(pastHeader);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('edited-$pastId')), findsOneWidget);
        expect(
          coordinator.entries
              .firstWhere((entry) => entry.id == '${expected.first}-fajr')
              .status,
          PrayerStatus.missed,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('failed corrections show an error and allow retry', (
    tester,
  ) async {
    final DateTime now = DateTime.utc(2026, 9, 11, 12);
    final _Coordinator coordinator = _Coordinator(now)..fail = true;
    await tester.pumpWidget(_app(coordinator, now));
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('tracker-header-2026-09-10'));
    await tester.scrollUntilVisible(header, 250);
    await tester.tap(header);
    await tester.pumpAndSettle();
    final Finder edit = find.byKey(const ValueKey('correct-2026-09-10-fajr'));
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ich habe gebetet'));
    await tester.pumpAndSettle();
    expect(coordinator.changes, 0);
    expect(find.byKey(const ValueKey('edited-2026-09-10-fajr')), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.widget<IconButton>(edit).onPressed, isNotNull);
    coordinator.fail = false;
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ich habe gebetet'));
    await tester.pumpAndSettle();
    expect(coordinator.changes, 1);
    expect(
      find.byKey(const ValueKey('edited-2026-09-10-fajr')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
