import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/theme/app_theme.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:salah_focus/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Notifications implements NotificationService {
  final List<DateTime> fridayReminderTimes = <DateTime>[];
  int fridayCancellations = 0;

  @override
  Future<void> cancelAllFridayPrayerNotifications() async {
    fridayCancellations++;
    fridayReminderTimes.clear();
  }

  @override
  Future<bool> notificationsAllowed() async => true;

  @override
  Future<void> scheduleFridayPrayerReminder({
    required String localDate,
    required DateTime reminderAtUtc,
    required String timezoneId,
    required String languageCode,
  }) async => fridayReminderTimes.add(reminderAtUtc);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _mount(
  WidgetTester tester,
  _Notifications notifications, {
  bool use24HourFormat = true,
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      initialPreferencesProvider.overrideWithValue(
        const AppPreferences(
          prayerSettings: PrayerSettings(),
          localeCode: 'en',
          themeMode: 'light',
          onboardingComplete: true,
        ),
      ),
      todayPrayerDayProvider.overrideWith((Ref ref) async => null),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
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
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Friday Prayer can be enabled and its time edited later', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final _Notifications notifications = _Notifications();
    final ProviderContainer container = await _mount(tester, notifications);

    final Finder toggle = find.byKey(
      const ValueKey<String>('friday-prayer-enabled'),
    );
    await tester.scrollUntilVisible(toggle, 250);
    expect(
      find.byKey(const ValueKey<String>('friday-prayer-time')),
      findsNothing,
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(
      container
          .read(settingsControllerProvider)
          .prayerSettings
          .fridayPrayer
          .enabled,
      isTrue,
    );
    expect(notifications.fridayCancellations, 1);
    expect(notifications.fridayReminderTimes, isEmpty);
    final Finder timeRow = find.byKey(
      const ValueKey<String>('friday-prayer-time'),
    );
    expect(timeRow, findsOneWidget);
    expect(find.text('Dhuhr time (automatic)'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('friday-prayer-mosque-note')),
      findsOneWidget,
    );

    await tester.tap(timeRow);
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(
      MediaQuery.alwaysUse24HourFormatOf(
        tester.element(find.byType(TimePickerDialog)),
      ),
      isTrue,
    );
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final Finder fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '14');
    await tester.enterText(fields.at(1), '45');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    final settings = container
        .read(settingsControllerProvider)
        .prayerSettings
        .fridayPrayer;
    expect(settings.enabled, isTrue);
    expect(settings.manualMinutesFromMidnight, 14 * 60 + 45);
    expect(find.text('14:45'), findsWidgets);

    expect(notifications.fridayCancellations, 2);
    expect(notifications.fridayReminderTimes, isEmpty);
    await tester.tap(find.byKey(const ValueKey<String>('friday-prayer-auto')));
    await tester.pumpAndSettle();
    expect(
      container
          .read(settingsControllerProvider)
          .prayerSettings
          .fridayPrayer
          .manualMinutesFromMidnight,
      isNull,
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      container
          .read(settingsControllerProvider)
          .prayerSettings
          .fridayPrayer
          .enabled,
      isFalse,
    );
    expect(notifications.fridayCancellations, 4);
    expect(notifications.fridayReminderTimes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Jumuah editor follows a 12-hour system preference', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final _Notifications notifications = _Notifications();
    await _mount(tester, notifications, use24HourFormat: false);
    final Finder toggle = find.byKey(
      const ValueKey<String>('friday-prayer-enabled'),
    );
    await tester.scrollUntilVisible(toggle, 250);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('friday-prayer-time')));
    await tester.pumpAndSettle();
    expect(
      MediaQuery.alwaysUse24HourFormatOf(
        tester.element(find.byType(TimePickerDialog)),
      ),
      isFalse,
    );
  });
}
