import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_tracker/presentation/tracker_screen.dart';
import 'package:salah_focus/features/settings/presentation/notification_settings_screen.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';

class _Permissions implements NotificationService {
  bool allowed = true;
  bool grantOnRequest = false;
  int requests = 0;
  int settingsOpened = 0;
  bool exactAllowed = false;
  int exactSettingsOpened = 0;
  bool fail = false;
  bool failInitialization = false;

  @override
  Future<void> initialize() async {
    if (failInitialization) throw StateError('Initialization unavailable');
  }

  @override
  Future<bool> notificationsAllowed() async {
    if (fail) throw StateError('Unavailable');
    return allowed;
  }

  @override
  Future<bool> requestPermission() async {
    requests++;
    allowed = grantOnRequest;
    return allowed;
  }

  @override
  Future<void> openNotificationSettings() async {
    settingsOpened++;
  }

  @override
  Future<bool> canScheduleExactly() async => exactAllowed;

  @override
  Future<void> openExactAlarmSettings() async {
    exactSettingsOpened++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget screen, ThemeData theme) => MaterialApp(
  theme: theme,
  locale: const Locale('de'),
  supportedLocales: AppStrings.supportedLocales,
  localizationsDelegates: const [
    AppStrings.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: screen,
);

double _contrast(Color foreground, Color background) {
  final double a = foreground.computeLuminance();
  final double b = background.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

void main() {
  setUpAll(initializeDateFormatting);

  for (final bool exact in [false, true]) {
    testWidgets(
      'system settings open after initialization fails (exact: $exact)',
      (tester) async {
        final service = _Permissions()..failInitialization = true;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [notificationServiceProvider.overrideWithValue(service)],
            child: _app(
              exact
                  ? const NotificationSettingsScreen.exactAlarms()
                  : const NotificationSettingsScreen(),
              AppTheme.dark(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithIcon(OutlinedButton, Icons.open_in_new_rounded),
        );
        await tester.pumpAndSettle();
        expect(service.settingsOpened, exact ? 0 : 1);
        expect(service.exactSettingsOpened, exact ? 1 : 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final bool initiallyAllowed in [false, true]) {
    testWidgets('exact alarm settings stay dark (allowed: $initiallyAllowed)', (
      tester,
    ) async {
      final _Permissions service = _Permissions()
        ..exactAllowed = initiallyAllowed
        ..allowed = !initiallyAllowed;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [notificationServiceProvider.overrideWithValue(service)],
          child: _app(const SettingsScreen(), AppTheme.dark()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Präzise Erinnerungen erlauben').hitTestable(),
        200,
      );
      await tester.tap(find.text('Präzise Erinnerungen erlauben'));
      await tester.pumpAndSettle();
      final Finder page = find.byType(NotificationSettingsScreen);
      expect(
        tester.widget<NotificationSettingsScreen>(page).isExactAlarm,
        isTrue,
      );
      expect(Theme.of(tester.element(page)).brightness, Brightness.dark);
      expect(
        Theme.of(tester.element(page)).scaffoldBackgroundColor
            .computeLuminance(),
        lessThan(0.1),
      );
      expect(
        find.text(
          initiallyAllowed
              ? 'Präzise Erinnerungen sind aktiviert'
              : 'Präzise Erinnerungen sind deaktiviert',
        ),
        findsOneWidget,
      );
      expect(service.exactSettingsOpened, 0);
      expect(service.settingsOpened, 0);
      expect(service.requests, 0);

      await tester.tap(find.text('Systemeinstellungen öffnen'));
      await tester.pumpAndSettle();
      expect(service.exactSettingsOpened, 1);
      expect(service.settingsOpened, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      service.exactAllowed = !initiallyAllowed;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        find.text(
          initiallyAllowed
              ? 'Präzise Erinnerungen sind deaktiviert'
              : 'Präzise Erinnerungen sind aktiviert',
        ),
        findsOneWidget,
      );
      expect(Theme.of(tester.element(page)).brightness, Brightness.dark);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'notification settings stay dark and open Android only explicitly',
    (tester) async {
      final _Permissions service = _Permissions();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [notificationServiceProvider.overrideWithValue(service)],
          child: _app(const SettingsScreen(), AppTheme.dark()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Benachrichtigungen erlauben').hitTestable(),
        200,
      );
      await tester.tap(find.text('Benachrichtigungen erlauben'));
      await tester.pumpAndSettle();
      final Finder page = find.byType(NotificationSettingsScreen);
      expect(page, findsOneWidget);
      expect(Theme.of(tester.element(page)).brightness, Brightness.dark);
      expect(find.text('Benachrichtigungen sind aktiviert'), findsOneWidget);
      expect(service.requests, 0);
      expect(service.settingsOpened, 0);
      final ThemeData theme = Theme.of(tester.element(page));
      expect(theme.scaffoldBackgroundColor.computeLuminance(), lessThan(0.1));
      await tester.tap(find.text('Systemeinstellungen öffnen'));
      await tester.pumpAndSettle();
      expect(service.settingsOpened, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      service.allowed = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Benachrichtigungen sind deaktiviert'), findsOneWidget);
      expect(Theme.of(tester.element(page)).brightness, Brightness.dark);
      service.grantOnRequest = true;
      await tester.tap(
        find.widgetWithText(FilledButton, 'Benachrichtigungen erlauben'),
      );
      await tester.pumpAndSettle();
      expect(service.requests, 1);
      expect(find.text('Benachrichtigungen sind aktiviert'), findsOneWidget);
      expect(service.settingsOpened, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('denied permission and read errors stay in the themed page', (
    tester,
  ) async {
    final _Permissions service = _Permissions()..allowed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationServiceProvider.overrideWithValue(service)],
        child: _app(const NotificationSettingsScreen(), AppTheme.dark()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Benachrichtigungen erlauben'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Benachrichtigungen sind deaktiviert'), findsOneWidget);
    expect(service.settingsOpened, 0);
    service.fail = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Erneut versuchen'), findsOneWidget);
    service.fail = false;
    service.allowed = true;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('Benachrichtigungen sind aktiviert'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
    testWidgets(
      '${theme.brightness.name} tracker text contrasts with every status background',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final List<PrayerEntry> entries = [];
        for (final (int day, int prayed) in [
          (8, 0),
          (9, 2),
          (10, 5),
          (11, 3),
        ]) {
          for (final PrayerType type in PrayerType.values) {
            final DateTime time = DateTime.utc(
              2026,
              9,
              day,
              5 + type.index * 3,
            );
            final String date = time.toIso8601String().substring(0, 10);
            entries.add(
              PrayerEntry(
                id: '$date-${type.name}',
                localDate: date,
                type: type,
                scheduledAtUtc: time,
                timezoneId: 'UTC',
                graceEndsAtUtc: time.add(const Duration(hours: 1)),
                trackingEndsAtUtc: time.add(const Duration(hours: 2)),
                status: type.index < prayed
                    ? PrayerStatus.prayed
                    : PrayerStatus.missed,
              ),
            );
          }
        }
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              trackerDataProvider.overrideWith(
                (ref) async => TrackerData(
                  entries: entries,
                  localNow: DateTime(2026, 9, 11),
                ),
              ),
            ],
            child: _app(const TrackerScreen(), theme),
          ),
        );
        await tester.pumpAndSettle();
        final Iterable<Card> todayCards = tester
            .widgetList<Card>(find.byType(Card))
            .where((card) => card.shape is RoundedRectangleBorder);
        expect(todayCards, isNotEmpty);
        for (final Card card in todayCards) {
          expect(
            _contrast(theme.colorScheme.onSurface, card.color!),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(theme.colorScheme.primary, card.color!),
            greaterThanOrEqualTo(3),
          );
          if (theme.brightness == Brightness.dark) {
            expect(card.color!.computeLuminance(), lessThan(0.1));
          }
        }
        await tester.scrollUntilVisible(find.text('Monat').hitTestable(), 300);
        await tester.pumpAndSettle();
        for (final int day in [8, 9, 10, 11, 12]) {
          final Finder cell = find.byKey(
            ValueKey('calendar-2026-09-${day.toString().padLeft(2, '0')}'),
          );
          await tester.ensureVisible(cell);
          final BoxDecoration decoration =
              tester.widget<DecoratedBox>(cell).decoration as BoxDecoration;
          for (final Text text in tester.widgetList<Text>(
            find.descendant(of: cell, matching: find.byType(Text)),
          )) {
            expect(
              _contrast(text.style!.color!, decoration.color!),
              greaterThanOrEqualTo(4.5),
              reason: '${theme.brightness} day $day: ${text.data}',
            );
          }
          if (theme.brightness == Brightness.dark) {
            expect(decoration.color!.computeLuminance(), lessThan(0.15));
          }
          if (day == 11) expect(decoration.border, isNotNull);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
