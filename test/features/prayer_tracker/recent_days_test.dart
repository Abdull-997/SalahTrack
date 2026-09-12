import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app_providers.dart';
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

Widget _app(_Coordinator coordinator, DateTime now) => ProviderScope(
  overrides: [
    initialPreferencesProvider.overrideWithValue(
      const AppPreferences(
        prayerSettings: PrayerSettings(),
        localeCode: 'de',
        themeMode: 'dark',
        onboardingComplete: true,
        location: UserLocation(
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
    locale: const Locale('de'),
    supportedLocales: AppStrings.supportedLocales,
    localizationsDelegates: const [
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const TrackerScreen(),
  ),
);

void main() {
  setUpAll(initializeDateFormatting);

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
