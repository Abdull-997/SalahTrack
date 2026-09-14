import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah_focus/app/app.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/router/app_router.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/notifications/prayer_notification_payload.dart';
import 'package:salah_focus/core/time/clock_service.dart';
import 'package:salah_focus/features/prayer_times/application/prayer_coordinator.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/presentation/prayer_reminder_screen.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';

class _Clock implements ClockService {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 9, 13, 20);
}

class _Notifications implements NotificationService {
  final controller = StreamController<String>.broadcast();
  Future<String?> initial = Future.value();
  @override
  Stream<String> get payloads => controller.stream;
  @override
  Future<String?> takeInitialPayload() => initial;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Coordinator implements PrayerCoordinator {
  final entries = <String, PrayerEntry>{};
  int reads = 0;
  int confirms = 0;
  int snoozes = 0;
  Object? readError;
  Object? actionError;
  Completer<void>? pending;

  @override
  Future<PrayerEntry?> prayerById(String id) async {
    reads++;
    if (readError != null) throw readError!;
    return entries[id];
  }

  @override
  Future<PrayerEntry> confirm(PrayerEntry prayer) async {
    confirms++;
    if (pending != null) await pending!.future;
    if (actionError != null) throw actionError!;
    return entries[prayer.id] = prayer.copyWith(status: PrayerStatus.prayed);
  }

  @override
  Future<PrayerEntry> snooze(
    PrayerEntry prayer,
    PrayerSettings settings,
    String prayerName,
    String languageCode,
  ) async {
    snoozes++;
    if (actionError != null) throw actionError!;
    return entries[prayer.id] = prayer.copyWith(
      status: PrayerStatus.snoozed,
      snoozeCount: prayer.snoozeCount + 1,
      snoozedUntilUtc: _Clock().nowUtc().add(
        Duration(minutes: settings.snoozeMinutes),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PrayerEntry _entry({PrayerType type = PrayerType.isha, int snoozes = 0}) =>
    PrayerEntry(
      id: '2026-09-13:${type.name}',
      localDate: '2026-09-13',
      type: type,
      scheduledAtUtc: DateTime.utc(2026, 9, 13, 19),
      timezoneId: 'UTC',
      graceEndsAtUtc: DateTime.utc(2026, 9, 13, 20),
      trackingEndsAtUtc: DateTime.utc(2026, 9, 13, 23),
      status: PrayerStatus.pending,
      snoozeCount: snoozes,
    );

String _payload({
  PrayerType prayer = PrayerType.isha,
  PrayerNotificationAction action = PrayerNotificationAction.open,
  String eventId = 'event-1',
}) => PrayerNotificationPayload(
  prayerId: _entry(type: prayer).id,
  action: action,
  eventId: eventId,
).encode();

Future<ProviderContainer> _mount(
  WidgetTester tester,
  _Notifications notifications,
  _Coordinator coordinator,
) async {
  final container = ProviderContainer(
    overrides: [
      initialPreferencesProvider.overrideWithValue(
        const AppPreferences(
          prayerSettings: PrayerSettings(),
          localeCode: 'en',
          themeMode: 'light',
          onboardingComplete: true,
        ),
      ),
      clockServiceProvider.overrideWithValue(_Clock()),
      notificationServiceProvider.overrideWithValue(notifications),
      prayerCoordinatorProvider.overrideWithValue(coordinator),
      todayPrayerDayProvider.overrideWith((ref) async => null),
    ],
  );
  final router = container.read(goRouterProvider);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    container.dispose();
    await notifications.controller.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SalahFocusApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  void testRouting(
    String description,
    WidgetTesterCallback callback, {
    TargetPlatform platform = TargetPlatform.android,
  }) {
    testWidgets(
      description,
      callback,
      variant: TargetPlatformVariant.only(platform),
    );
  }

  TestWidgetsFlutterBinding.ensureInitialized();
  const alarmChannel = MethodChannel('salah_focus/prayer_alarm');
  final alarmStates = <bool>[];
  setUpAll(initializeDateFormatting);
  setUp(() {
    alarmStates.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(alarmChannel, (call) async {
          alarmStates.add((call.arguments as Map)['active'] as bool);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(alarmChannel, null);
  });

  testRouting('cold body tap opens Isha and Android blocks Back until choice', (
    tester,
  ) async {
    final notifications = _Notifications()..initial = Future.value(_payload());
    final coordinator = _Coordinator()..entries[_entry().id] = _entry();
    final container = await _mount(tester, notifications, coordinator);
    expect(find.byType(PrayerReminderScreen), findsOneWidget);
    expect(find.text('Isha'), findsOneWidget);
    expect(find.text('Mark as Prayed'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Skip today'), findsNothing);
    expect(
      tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
      isFalse,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/reminder/2026-09-13:isha',
    );
    expect(alarmStates.last, isTrue);
    await tester.tap(find.text('Mark as Prayed'));
    await tester.pumpAndSettle();
    expect(coordinator.confirms, 1);
    expect(find.text('Alhamdulillah'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(
      tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
      isTrue,
    );
    expect(alarmStates.last, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Alhamdulillah'), findsOneWidget);
  });

  testRouting(
    'Friday Prayer tap opens Home without a decision or prayer state lookup',
    (tester) async {
      final notifications = _Notifications()
        ..initial = Future.value(
          const PrayerNotificationPayload(
            prayerId: 'friday-prayer-2-hours',
            kind: 'fridayPrayer',
          ).encode(),
        );
      final coordinator = _Coordinator();
      final container = await _mount(tester, notifications, coordinator);

      expect(
        container
            .read(goRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/home',
      );
      expect(find.byType(PrayerReminderScreen), findsNothing);
      expect(find.text('Mark as Prayed'), findsNothing);
      expect(find.text('Snooze'), findsNothing);
      expect(coordinator.reads, 0);
      expect(coordinator.confirms, 0);
      expect(coordinator.snoozes, 0);
    },
  );

  testRouting(
    'one-hour remaining tap opens Home without the decision workflow',
    (tester) async {
      final notifications = _Notifications()
        ..initial = Future.value(
          const PrayerNotificationPayload(
            prayerId: '2026-09-13:dhuhr',
            kind: 'oneHourRemaining',
          ).encode(),
        );
      final coordinator = _Coordinator();
      final container = await _mount(tester, notifications, coordinator);

      expect(
        container
            .read(goRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/home',
      );
      expect(find.byType(PrayerReminderScreen), findsNothing);
      expect(find.text('Mark as Prayed'), findsNothing);
      expect(find.text('Snooze'), findsNothing);
      expect(coordinator.reads, 0);
      expect(coordinator.confirms, 0);
      expect(coordinator.snoozes, 0);
    },
  );

  testRouting(
    'warm Mark as Prayed opens target, executes once and stays on success',
    (tester) async {
      final notifications = _Notifications();
      final coordinator = _Coordinator()..entries[_entry().id] = _entry();
      await _mount(tester, notifications, coordinator);
      coordinator.pending = Completer<void>();
      final payload = _payload(action: PrayerNotificationAction.markPrayed);
      notifications.controller.add(payload);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('Isha'), findsOneWidget);
      expect(coordinator.confirms, 1);
      notifications.controller.add(payload);
      await tester.pump();
      coordinator.pending!.complete();
      await tester.pumpAndSettle();
      expect(coordinator.confirms, 1);
      expect(find.text('Alhamdulillah'), findsOneWidget);
    },
  );

  testRouting('Snooze response acts on Isha and navigates home after success', (
    tester,
  ) async {
    final notifications = _Notifications()
      ..initial = Future.value(
        _payload(action: PrayerNotificationAction.snooze),
      );
    final coordinator = _Coordinator()..entries[_entry().id] = _entry();
    final container = await _mount(tester, notifications, coordinator);
    expect(coordinator.snoozes, 1);
    expect(coordinator.entries[_entry().id]!.snoozeCount, 1);
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/home',
    );
    expect(alarmStates.last, isFalse);
  });

  testRouting(
    'iOS reminder always offers Home and never enables Android alarm flags',
    (tester) async {
      final notifications = _Notifications()
        ..initial = Future.value(_payload());
      final coordinator = _Coordinator()..entries[_entry().id] = _entry();
      await _mount(tester, notifications, coordinator);
      expect(find.text('Isha'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(
        tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
        isTrue,
      );
      expect(alarmStates, isEmpty);
    },
    platform: TargetPlatform.iOS,
  );

  testRouting('warm response wins over a delayed cold-launch payload', (
    tester,
  ) async {
    final launch = Completer<String?>();
    final notifications = _Notifications()..initial = launch.future;
    final coordinator = _Coordinator()
      ..entries[_entry().id] = _entry()
      ..entries[_entry(type: PrayerType.fajr).id] = _entry(
        type: PrayerType.fajr,
      );
    await _mount(tester, notifications, coordinator);
    notifications.controller.add(_payload());
    await tester.pumpAndSettle();
    launch.complete(_payload(prayer: PrayerType.fajr, eventId: 'old'));
    await tester.pumpAndSettle();
    expect(find.text('Isha'), findsOneWidget);
    expect(find.text('Fajr'), findsNothing);
  });

  testRouting('reopening rereads storage instead of a cached pending prayer', (
    tester,
  ) async {
    final notifications = _Notifications();
    final coordinator = _Coordinator()..entries[_entry().id] = _entry();
    final container = await _mount(tester, notifications, coordinator);
    await container.read(prayerByIdProvider(_entry().id).future);
    coordinator.entries[_entry().id] = _entry().copyWith(
      status: PrayerStatus.prayed,
    );
    notifications.controller.add(
      _payload(action: PrayerNotificationAction.markPrayed),
    );
    await tester.pumpAndSettle();
    expect(coordinator.reads, 2);
    expect(coordinator.confirms, 0);
    expect(find.text('Alhamdulillah'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testRouting('a later identical tap retries a failed load', (tester) async {
    final notifications = _Notifications();
    final coordinator = _Coordinator()
      ..entries[_entry().id] = _entry()
      ..readError = StateError('temporary failure');
    await _mount(tester, notifications, coordinator);
    notifications.controller.add(_payload());
    await tester.pumpAndSettle();
    expect(coordinator.reads, 1);
    coordinator.readError = null;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2100)),
    );
    notifications.controller.add(_payload());
    await tester.pumpAndSettle();
    expect(coordinator.reads, 2);
    expect(find.text('Isha'), findsOneWidget);
  });

  for (final unavailable in [
    'missing',
    'loadError',
    'maxSnoozes',
    'expired',
    'final',
  ]) {
    testRouting('$unavailable does not trap Android into false confirmation', (
      tester,
    ) async {
      final notifications = _Notifications()
        ..initial = Future.value(_payload());
      final coordinator = _Coordinator();
      switch (unavailable) {
        case 'missing':
          break;
        case 'loadError':
          coordinator.readError = StateError('unavailable');
        case 'maxSnoozes':
          coordinator.entries[_entry().id] = _entry(snoozes: 2);
        case 'expired':
          coordinator.entries[_entry().id] = _entry().copyWith(
            trackingEndsAtUtc: _Clock().nowUtc().add(
              const Duration(minutes: 10),
            ),
          );
        case 'final':
          coordinator.entries[_entry().id] = _entry().copyWith(
            status: PrayerStatus.missed,
          );
      }
      await _mount(tester, notifications, coordinator);
      expect(find.text('Home'), findsOneWidget);
      expect(
        tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
        isTrue,
      );
      expect(coordinator.confirms, 0);
      expect(alarmStates.last, isFalse);
    });
  }

  testRouting(
    'action errors keep target visible and release Back and alarm flags',
    (tester) async {
      final notifications = _Notifications()
        ..initial = Future.value(_payload());
      final coordinator = _Coordinator()
        ..entries[_entry().id] = _entry()
        ..actionError = StateError('cannot schedule');
      await _mount(tester, notifications, coordinator);
      await tester.tap(find.byIcon(Icons.snooze_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Isha'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(
        tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
        isTrue,
      );
      expect(alarmStates.last, isFalse);
      expect(coordinator.confirms, 0);
    },
  );
}
