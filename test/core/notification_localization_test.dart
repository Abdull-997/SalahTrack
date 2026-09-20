import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/notifications/local_notification_service.dart';
import 'package:salah_focus/core/notifications/notification_ids.dart';
import 'package:salah_focus/core/notifications/prayer_notification_payload.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:timezone/timezone.dart';

class _Plugin implements FlutterLocalNotificationsPlugin {
  final List<
    ({
      String? title,
      String? body,
      NotificationDetails details,
      String? payload,
      int id,
      TZDateTime scheduledDate,
      DateTimeComponents? matchDateTimeComponents,
    })
  >
  scheduled = [];
  InitializationSettings? settings;
  DidReceiveNotificationResponseCallback? onResponse;
  NotificationAppLaunchDetails? launchDetails;
  Completer<void>? initializeGate;
  int initializeCalls = 0;
  bool failSchedule = false;
  final List<int> cancelled = [];
  final List<PendingNotificationRequest> pending = [];

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalls++;
    this.settings = settings;
    onResponse = onDidReceiveNotificationResponse;
    await initializeGate?.future;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => launchDetails;

  @override
  Future<void> cancel({required int id, String? tag}) async =>
      cancelled.add(id);

  @override
  Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async => pending;

  @override
  Future<void> zonedSchedule({
    required int id,
    required TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (failSchedule) throw StateError('Scheduling failed');
    scheduled.add((
      id: id,
      title: title,
      body: body,
      details: notificationDetails,
      payload: payload,
      scheduledDate: scheduledDate,
      matchDateTimeComponents: matchDateTimeComponents,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel settingsChannel = MethodChannel(
    'salah_focus/system_settings',
  );
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settingsChannel, (call) async {
          if (call.method == 'canUseFullScreenIntent') return true;
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settingsChannel, null);
  });

  test('prayer alert falls back to a normal notification when full screen is denied', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settingsChannel, (call) async {
          if (call.method == 'canUseFullScreenIntent') return false;
          return null;
        });
    final _Plugin plugin = _Plugin();
    final LocalNotificationService service = LocalNotificationService(
      plugin: plugin,
    );
    final DateTime later = DateTime.now().toUtc().add(const Duration(hours: 2));
    final PrayerEntry entry = PrayerEntry(
      id: 'test-fajr',
      localDate: later.toIso8601String().substring(0, 10),
      type: PrayerType.fajr,
      scheduledAtUtc: later,
      timezoneId: 'UTC',
      graceEndsAtUtc: later.add(const Duration(hours: 1)),
      trackingEndsAtUtc: later.add(const Duration(hours: 2)),
      status: PrayerStatus.upcoming,
    );
    await service.schedulePrayer(entry, 'Fajr', languageCode: 'en');
    expect(plugin.scheduled, hasLength(1));
    expect(plugin.scheduled.single.details.android!.fullScreenIntent, isFalse);
    expect(
      plugin.scheduled.single.details.android!.importance,
      Importance.high,
    );
  });
  for (final String code in <String>[
    'tr',
    'fr',
    'es',
    'id',
    'bn',
    'pa',
    'fa',
    'ms',
  ]) {
    test(
      '$code localizes every scheduled reminder and Android channel',
      () async {
        final _Plugin plugin = _Plugin();
        final LocalNotificationService service = LocalNotificationService(
          plugin: plugin,
          languageCode: () => code,
        );
        final DateTime later = DateTime.now().toUtc().add(
          const Duration(hours: 2),
        );
        final PrayerEntry entry = PrayerEntry(
          id: 'test-isha',
          localDate: later.toIso8601String().substring(0, 10),
          type: PrayerType.isha,
          scheduledAtUtc: later,
          timezoneId: 'UTC',
          graceEndsAtUtc: later.add(const Duration(hours: 1)),
          trackingEndsAtUtc: later.add(const Duration(hours: 2)),
          snoozedUntilUtc: later,
          status: PrayerStatus.snoozed,
        );
        final String name = entry.type.localizedName(code);
        await service.schedulePrayer(entry, name, languageCode: code);
        await service.scheduleGraceReminder(entry, name, languageCode: code);
        await service.scheduleSnoozeReminder(entry, name, languageCode: code);
        await service.scheduleSoftReminder(entry, name, languageCode: code);
        expect(plugin.scheduled, hasLength(4));
        final List<String> titles = switch (code) {
          'tr' => [
            '🕌 Yatsı vakti geldi',
            'Yatsı vakti',
            'Yatsı – hatırlatma',
            'Nazik bir hatırlatma 🤍',
          ],
          'fr' => [
            '🕌 C’est l’heure de Icha',
            'L’heure de Icha',
            'Icha – rappel',
            'Un petit rappel 🤍',
          ],
          'es' => [
            '🕌 Es la hora de Isha',
            'Hora de Isha',
            'Isha – recordatorio',
            'Un pequeño recordatorio 🤍',
          ],
          'id' => [
            '🕌 Waktu Isya telah tiba',
            'Waktu Isya',
            'Isya – pengingat',
            'Pengingat lembut 🤍',
          ],
          'bn' => [
            '🕌 ইশা-এর সময় হয়েছে',
            'ইশা-এর সময়',
            'ইশা – স্মরণিকা',
            'একটি কোমল স্মরণিকা 🤍',
          ],
          'pa' => [
            '🕌 عشاء دا ویلا ہو گیا',
            'عشاء دا ویلا',
            'عشاء – یاددہانی',
            'اک ہولی یاددہانی 🤍',
          ],
          'fa' => [
            '🕌 وقت عشا فرا رسیده است',
            'وقت عشا',
            'عشا – یادآوری',
            'یک یادآوری ملایم 🤍',
          ],
          _ => [
            '🕌 Waktu Isyak telah tiba',
            'Waktu Isyak',
            'Isyak – peringatan',
            'Peringatan lembut 🤍',
          ],
        };
        expect(plugin.scheduled.map((item) => item.title), titles);
        final String channelName = switch (code) {
          'tr' => 'Namaz hatırlatmaları',
          'fr' => 'Rappels de prière',
          'es' => 'Recordatorios de oración',
          'id' => 'Pengingat salat',
          'bn' => 'নামাজের স্মরণিকা',
          'pa' => 'نماز دیاں یاددہانیاں',
          'fa' => 'یادآوری‌های نماز',
          _ => 'Peringatan solat',
        };
        expect(plugin.scheduled[1].details.android!.channelName, channelName);
        expect(
          plugin.scheduled[1].details.android!.channelId,
          'prayer_alarms_v2',
        );
        for (final item in plugin.scheduled) {
          expect(item.body, isNotEmpty);
          expect(item.body, isNot(contains('your')));
          expect(item.body, isNot(contains('{prayer}')));
        }
        expect(
          PrayerNotificationPayload.tryParse(plugin.scheduled.last.payload)!
              .kind,
          'soft',
        );
        for (final item in plugin.scheduled.take(3)) {
          final android = item.details.android!;
          expect(android.fullScreenIntent, isTrue);
          expect(android.ongoing, isTrue);
          expect(android.autoCancel, isFalse);
          expect(android.category, AndroidNotificationCategory.alarm);
          expect(android.audioAttributesUsage, AudioAttributesUsage.alarm);
          expect(android.actions!.map((action) => action.id), [
            'mark_prayed',
            'snooze',
          ]);
          expect(
            android.actions!.every(
              (action) =>
                  action.showsUserInterface && !action.cancelNotification,
            ),
            isTrue,
          );
          expect(
            item.details.iOS!.interruptionLevel,
            InterruptionLevel.timeSensitive,
          );
          expect(item.details.iOS!.categoryIdentifier, 'prayer_actions_$code');
          expect(
            PrayerNotificationPayload.tryParse(item.payload)!.eventId,
            isNotEmpty,
          );
        }
        final category = plugin.settings!.iOS!.notificationCategories
            .singleWhere(
              (category) => category.identifier == 'prayer_actions_$code',
            );
        expect(category.actions.map((action) => action.identifier), [
          'mark_prayed',
          'snooze',
        ]);
        expect(
          category.actions.every(
            (action) => action.options.contains(
              DarwinNotificationActionOption.foreground,
            ),
          ),
          isTrue,
        );
        expect(
          plugin.scheduled.last.details.android!.fullScreenIntent,
          isFalse,
        );
      },
    );
  }

  test(
    'cold-start responses preserve the action and are consumed once',
    () async {
      final plugin = _Plugin()
        ..launchDetails = const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            actionId: 'mark_prayed',
            payload: 'prayer:2026-09-13:isha',
          ),
        );
      final service = LocalNotificationService(plugin: plugin);
      final payload = PrayerNotificationPayload.tryParse(
        await service.takeInitialPayload(),
      )!;
      expect(payload.prayerId, '2026-09-13:isha');
      expect(payload.action, PrayerNotificationAction.markPrayed);
      expect(await service.takeInitialPayload(), isNull);
    },
  );

  test(
    'initialization is shared and early action callbacks are buffered',
    () async {
      final plugin = _Plugin()..initializeGate = Completer<void>();
      final service = LocalNotificationService(plugin: plugin);
      final first = service.initialize();
      final second = service.initialize();
      plugin.onResponse!(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: 'snooze',
          payload: 'reminder:2026-09-13:isha',
        ),
      );
      plugin.initializeGate!.complete();
      await Future.wait([first, second]);
      expect(plugin.initializeCalls, 1);
      final payload = PrayerNotificationPayload.tryParse(
        await service.payloads.first,
      )!;
      expect(payload.action, PrayerNotificationAction.snooze);
      expect(payload.prayerId, '2026-09-13:isha');
    },
  );

  test('malformed and dismissal responses do not navigate', () async {
    final plugin = _Plugin();
    final service = LocalNotificationService(plugin: plugin);
    await service.initialize();
    final values = <String>[];
    final subscription = service.payloads.listen(values.add);
    plugin.onResponse!(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'invalid',
      ),
    );
    plugin.onResponse!(
      const NotificationResponse(
        notificationResponseType:
            NotificationResponseType.notificationDismissed,
        payload: 'prayer:2026-09-13:isha',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(values, isEmpty);
    await subscription.cancel();
  });

  test(
    'snooze schedules a different slot before cancelling the delivered alert',
    () async {
      final plugin = _Plugin();
      final service = LocalNotificationService(plugin: plugin);
      final now = DateTime.now().toUtc();
      final entry = PrayerEntry(
        id: '2026-09-13:isha',
        localDate: '2026-09-13',
        type: PrayerType.isha,
        scheduledAtUtc: now,
        timezoneId: 'UTC',
        graceEndsAtUtc: now,
        trackingEndsAtUtc: now.add(const Duration(hours: 4)),
        status: PrayerStatus.snoozed,
        snoozeCount: 1,
        snoozedUntilUtc: now.add(const Duration(minutes: 20)),
      );
      plugin.failSchedule = true;
      await expectLater(
        service.scheduleSnoozeReminder(entry, 'Isha', languageCode: 'en'),
        throwsStateError,
      );
      expect(plugin.cancelled, isEmpty);
      plugin.failSchedule = false;
      await service.scheduleSnoozeReminder(entry, 'Isha', languageCode: 'en');
      expect(plugin.scheduled.single.id, NotificationIds.snooze(entry));
      final deliveredAt = plugin.scheduled.single.scheduledDate.toUtc();
      expect(deliveredAt.isBefore(entry.snoozedUntilUtc!), isFalse);
      expect(
        deliveredAt.difference(entry.snoozedUntilUtc!),
        lessThan(const Duration(seconds: 1)),
      );
      expect(deliveredAt.microsecond, 0);
      expect(deliveredAt.millisecond, 0);
      expect(plugin.cancelled, contains(NotificationIds.previousSnooze(entry)));
      expect(plugin.cancelled, isNot(contains(NotificationIds.snooze(entry))));
      await service.cancelPrayer(entry);
      expect(plugin.cancelled, contains(NotificationIds.snooze(entry)));
      expect(
        plugin.cancelled,
        contains(NotificationIds.oneHourRemaining(entry)),
      );
    },
  );

  test(
    'one-hour remaining reminder uses the next prayer and is action-free',
    () async {
      final plugin = _Plugin();
      final service = LocalNotificationService(plugin: plugin);
      final now = DateTime.now().toUtc();
      final dhuhr = PrayerEntry(
        id: '2026-09-13:dhuhr',
        localDate: '2026-09-13',
        type: PrayerType.dhuhr,
        scheduledAtUtc: now.add(const Duration(hours: 1)),
        timezoneId: 'UTC',
        graceEndsAtUtc: now.add(const Duration(hours: 2)),
        trackingEndsAtUtc: now.add(const Duration(hours: 5)),
        status: PrayerStatus.upcoming,
      );
      final asr = PrayerEntry(
        id: '2026-09-13:asr',
        localDate: '2026-09-13',
        type: PrayerType.asr,
        scheduledAtUtc: now.add(const Duration(hours: 3)),
        timezoneId: 'UTC',
        graceEndsAtUtc: now.add(const Duration(hours: 4)),
        trackingEndsAtUtc: now.add(const Duration(hours: 7)),
        status: PrayerStatus.upcoming,
      );

      await service.scheduleOneHourRemainingReminder(
        dhuhr,
        asr,
        'Dhuhr',
        'Asr',
        languageCode: 'en',
      );

      final item = plugin.scheduled.single;
      expect(item.id, NotificationIds.oneHourRemaining(dhuhr));
      expect(item.title, 'Dhuhr not confirmed yet');
      expect(item.body, 'You have about 1 hour left before Asr begins.');
      final expected = asr.scheduledAtUtc.subtract(const Duration(hours: 1));
      expect(item.scheduledDate.toUtc().isBefore(expected), isFalse);
      expect(
        item.scheduledDate.toUtc().difference(expected),
        lessThan(const Duration(seconds: 1)),
      );
      expect(item.matchDateTimeComponents, isNull);
      final android = item.details.android!;
      expect(android.channelId, 'prayer_reminders');
      expect(android.fullScreenIntent, isFalse);
      expect(android.ongoing, isFalse);
      expect(android.autoCancel, isTrue);
      expect(android.category, AndroidNotificationCategory.reminder);
      expect(android.audioAttributesUsage, AudioAttributesUsage.notification);
      expect(android.actions, isEmpty);
      expect(item.details.iOS!.categoryIdentifier, isNull);
      final payload = PrayerNotificationPayload.tryParse(item.payload)!;
      expect(payload.kind, 'oneHourRemaining');
      expect(payload.action, PrayerNotificationAction.open);
      expect(payload.routeLocation, '/home');
    },
  );

  test(
    'Friday Prayer reminders are weekly, localized, and action-free',
    () async {
      final plugin = _Plugin();
      final service = LocalNotificationService(
        plugin: plugin,
        languageCode: () => 'en',
      );
      final DateTime friday = DateTime.now().toUtc().add(
        const Duration(days: 7),
      );

      await service.scheduleFridayPrayerReminder(
        firstReminderAtUtc: friday,
        timezoneId: 'UTC',
        hoursBefore: 2,
        languageCode: 'en',
      );
      await service.scheduleFridayPrayerReminder(
        firstReminderAtUtc: friday.add(const Duration(hours: 1)),
        timezoneId: 'UTC',
        hoursBefore: 1,
        languageCode: 'en',
      );

      expect(plugin.scheduled, hasLength(2));
      expect(plugin.scheduled.map((item) => item.id), <int>[
        NotificationIds.fridayPrayer(2),
        NotificationIds.fridayPrayer(1),
      ]);
      expect(plugin.scheduled.map((item) => item.body), <String>[
        'Friday Prayer is in 2 hours.',
        'Friday Prayer is in 1 hour.',
      ]);
      for (final item in plugin.scheduled) {
        expect(
          item.matchDateTimeComponents,
          DateTimeComponents.dayOfWeekAndTime,
        );
        final AndroidNotificationDetails android = item.details.android!;
        expect(android.channelId, 'friday_prayer_reminders');
        expect(android.fullScreenIntent, isFalse);
        expect(android.ongoing, isFalse);
        expect(android.autoCancel, isTrue);
        expect(android.category, AndroidNotificationCategory.reminder);
        expect(android.audioAttributesUsage, AudioAttributesUsage.notification);
        expect(android.actions, isEmpty);
        expect(item.details.iOS!.categoryIdentifier, isNull);
        final PrayerNotificationPayload payload =
            PrayerNotificationPayload.tryParse(item.payload)!;
        expect(payload.kind, 'fridayPrayer');
        expect(payload.action, PrayerNotificationAction.open);
        expect(payload.routeLocation, '/home');
      }
    },
  );

  test('planner cancellation recognizes both structured and legacy prayer payloads', () async {
    final plugin = _Plugin()
      ..pending.addAll([
        const PendingNotificationRequest(1, null, null, 'prayer:old-isha'),
        PendingNotificationRequest(
          2,
          null,
          null,
          const PrayerNotificationPayload(
            prayerId: 'new-isha',
            kind: 'snooze',
          ).encode(),
        ),
        const PendingNotificationRequest(3, null, null, 'soft:old-isha'),
        const PendingNotificationRequest(4, null, null, 'another-feature'),
        PendingNotificationRequest(
          5,
          null,
          null,
          const PrayerNotificationPayload(
            prayerId: 'friday-prayer-2-hours',
            kind: 'fridayPrayer',
          ).encode(),
        ),
        PendingNotificationRequest(
          6,
          null,
          null,
          const PrayerNotificationPayload(
            prayerId: 'new-dhuhr',
            kind: 'oneHourRemaining',
          ).encode(),
        ),
      ]);
    await LocalNotificationService(plugin: plugin)
        .cancelAllFuturePrayerNotifications();
    expect(plugin.cancelled, [1, 2, 6]);
  });

  test(
    'Friday Prayer cancellation leaves normal prayer reminders alone',
    () async {
      final plugin = _Plugin()
        ..pending.addAll([
          PendingNotificationRequest(
            1,
            null,
            null,
            const PrayerNotificationPayload(prayerId: 'normal-prayer').encode(),
          ),
          PendingNotificationRequest(
            2,
            null,
            null,
            const PrayerNotificationPayload(
              prayerId: 'friday-prayer-1-hours',
              kind: 'fridayPrayer',
            ).encode(),
          ),
        ]);

      await LocalNotificationService(plugin: plugin)
          .cancelAllFridayPrayerNotifications();

      expect(plugin.cancelled, isNot(contains(1)));
      expect(plugin.cancelled, contains(2));
      expect(plugin.cancelled, contains(NotificationIds.fridayPrayer(2)));
      expect(plugin.cancelled, contains(NotificationIds.fridayPrayer(1)));
    },
  );
}
