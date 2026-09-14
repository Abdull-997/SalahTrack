import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/core/notifications/prayer_notification_planner.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';

void main() {
  test(
    'planner schedules prayer and grace reminder for future prayer',
    () async {
      final FakeNotificationService service = FakeNotificationService();
      final PrayerNotificationPlanner planner = PrayerNotificationPlanner(
        service,
      );
      final PrayerEntry entry = _entry(DateTime.utc(2026, 8, 15, 10));

      await planner.reschedule(
        <PrayerEntry>[entry],
        prayerName: (_) => 'Dhuhr',
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 8, 14, 10),
      );

      expect(service.cancelledPending, 1);
      expect(service.prayers, <String>[entry.id]);
      expect(service.grace, <String>[entry.id]);
    },
  );

  test('planner ignores final prayers', () async {
    final FakeNotificationService service = FakeNotificationService();
    final PrayerNotificationPlanner planner = PrayerNotificationPlanner(
      service,
    );
    final PrayerEntry entry = _entry(DateTime.utc(2026, 8, 15, 10))
        .copyWith(status: PrayerStatus.prayed);

    await planner.reschedule(
      <PrayerEntry>[entry],
      prayerName: (_) => 'Dhuhr',
      languageCode: 'en',
      nowUtc: DateTime.utc(2026, 8, 14, 10),
    );

    expect(service.prayers, isEmpty);
    expect(service.grace, isEmpty);
  });

  test(
    'an active snooze suppresses prayer and grace alerts during refresh',
    () async {
      final service = FakeNotificationService();
      final now = DateTime.utc(2026, 8, 15, 10);
      final entry = _entry(now).copyWith(
        status: PrayerStatus.snoozed,
        snoozedUntilUtc: now.add(const Duration(minutes: 20)),
      );
      await PrayerNotificationPlanner(service).reschedule(
        [entry],
        prayerName: (_) => 'Dhuhr',
        languageCode: 'en',
        nowUtc: now,
      );
      expect(service.prayers, isEmpty);
      expect(service.grace, isEmpty);
      expect(service.snoozes, [entry.id]);
    },
  );

  test(
    'one-hour reminders use only the three requested prayer pairs',
    () async {
      final service = FakeNotificationService();
      final entries = <PrayerEntry>[
        _entryFor(PrayerType.fajr, DateTime.utc(2026, 8, 15, 5)),
        _entryFor(PrayerType.dhuhr, DateTime.utc(2026, 8, 15, 13, 28)),
        _entryFor(PrayerType.asr, DateTime.utc(2026, 8, 15, 16)),
        _entryFor(PrayerType.maghrib, DateTime.utc(2026, 8, 15, 19)),
        _entryFor(PrayerType.isha, DateTime.utc(2026, 8, 15, 20, 30)),
      ];

      await PrayerNotificationPlanner(service).reschedule(
        entries,
        prayerName: (entry) => entry.type.name,
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 8, 15, 10),
      );

      expect(
        service.oneHourRemaining,
        <({String prayerId, String nextPrayerId, DateTime scheduledAtUtc})>[
          (
            prayerId: '2026-08-15:dhuhr',
            nextPrayerId: '2026-08-15:asr',
            scheduledAtUtc: DateTime.utc(2026, 8, 15, 15),
          ),
          (
            prayerId: '2026-08-15:asr',
            nextPrayerId: '2026-08-15:maghrib',
            scheduledAtUtc: DateTime.utc(2026, 8, 15, 18),
          ),
          (
            prayerId: '2026-08-15:maghrib',
            nextPrayerId: '2026-08-15:isha',
            scheduledAtUtc: DateTime.utc(2026, 8, 15, 19, 30),
          ),
        ],
      );
    },
  );

  test('confirmed prayers do not receive a one-hour reminder', () async {
    final service = FakeNotificationService();
    await PrayerNotificationPlanner(service).reschedule(
      <PrayerEntry>[
        _entryFor(
          PrayerType.dhuhr,
          DateTime.utc(2026, 8, 15, 13, 28),
          status: PrayerStatus.prayed,
        ),
        _entryFor(PrayerType.asr, DateTime.utc(2026, 8, 15, 16)),
        _entryFor(PrayerType.maghrib, DateTime.utc(2026, 8, 15, 19)),
        _entryFor(PrayerType.isha, DateTime.utc(2026, 8, 15, 20, 30)),
      ],
      prayerName: (entry) => entry.type.name,
      languageCode: 'en',
      nowUtc: DateTime.utc(2026, 8, 15, 10),
    );

    expect(service.oneHourRemaining.map((item) => item.prayerId), <String>[
      '2026-08-15:asr',
      '2026-08-15:maghrib',
    ]);
  });

  test(
    'rescheduling replaces reminders and uses updated prayer times',
    () async {
      final service = FakeNotificationService();
      final planner = PrayerNotificationPlanner(service);
      List<PrayerEntry> entries({required int asrMinute}) => <PrayerEntry>[
        _entryFor(PrayerType.dhuhr, DateTime.utc(2026, 8, 15, 13, 28)),
        _entryFor(PrayerType.asr, DateTime.utc(2026, 8, 15, 16, asrMinute)),
        _entryFor(PrayerType.maghrib, DateTime.utc(2026, 8, 15, 19)),
        _entryFor(PrayerType.isha, DateTime.utc(2026, 8, 15, 20, 30)),
      ];

      await planner.reschedule(
        entries(asrMinute: 0),
        prayerName: (entry) => entry.type.name,
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 8, 15, 10),
      );
      await planner.reschedule(
        entries(asrMinute: 5),
        prayerName: (entry) => entry.type.name,
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 8, 15, 10),
      );

      expect(service.cancelledPending, 2);
      expect(service.oneHourRemaining, hasLength(3));
      expect(
        service.oneHourRemaining.first.scheduledAtUtc,
        DateTime.utc(2026, 8, 15, 15, 5),
      );
    },
  );
}

PrayerEntry _entry(DateTime scheduled) => PrayerEntry(
  id: '2026-08-15:dhuhr',
  localDate: '2026-08-15',
  type: PrayerType.dhuhr,
  scheduledAtUtc: scheduled,
  timezoneId: 'Europe/Berlin',
  graceEndsAtUtc: scheduled.add(const Duration(hours: 1)),
  trackingEndsAtUtc: scheduled.add(const Duration(hours: 4)),
  status: PrayerStatus.upcoming,
);

PrayerEntry _entryFor(
  PrayerType type,
  DateTime scheduled, {
  PrayerStatus status = PrayerStatus.upcoming,
}) => PrayerEntry(
  id: '2026-08-15:${type.name}',
  localDate: '2026-08-15',
  type: type,
  scheduledAtUtc: scheduled,
  timezoneId: 'Europe/Berlin',
  graceEndsAtUtc: scheduled.add(const Duration(hours: 1)),
  trackingEndsAtUtc: scheduled.add(const Duration(hours: 4)),
  status: status,
);

class FakeNotificationService implements NotificationService {
  @override
  Stream<String> get payloads => const Stream<String>.empty();

  final List<String> prayers = <String>[];
  final List<String> grace = <String>[];
  final List<String> snoozes = <String>[];
  final List<({String prayerId, String nextPrayerId, DateTime scheduledAtUtc})>
  oneHourRemaining =
      <({String prayerId, String nextPrayerId, DateTime scheduledAtUtc})>[];
  int cancelledPending = 0;

  @override
  Future<bool> canScheduleExactly() async => true;

  @override
  Future<bool> canUseFullScreenIntent() async => true;

  @override
  Future<bool> requestFullScreenIntentPermission() async => true;

  @override
  Future<void> openFullScreenIntentSettings() async {}

  @override
  Future<String?> takeInitialPayload() async => null;

  @override
  Future<void> cancelAllFuturePrayerNotifications() async {
    cancelledPending++;
    oneHourRemaining.clear();
  }

  @override
  Future<void> cancelAllFridayPrayerNotifications() async {}

  @override
  Future<void> cancelPrayer(PrayerEntry prayer) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestExactAlarmPermission() async => true;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> notificationsAllowed() async => true;

  @override
  Future<void> scheduleGraceReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  }) async => grace.add(prayer.id);

  @override
  Future<void> schedulePrayer(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  }) async => prayers.add(prayer.id);

  @override
  Future<void> scheduleSnoozeReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  }) async => snoozes.add(prayer.id);

  @override
  Future<void> scheduleSoftReminder(
    PrayerEntry prayer,
    String prayerName, {
    required String languageCode,
  }) async {}

  @override
  Future<void> scheduleOneHourRemainingReminder(
    PrayerEntry prayer,
    PrayerEntry nextPrayer,
    String prayerName,
    String nextPrayerName, {
    required String languageCode,
  }) async => oneHourRemaining.add((
    prayerId: prayer.id,
    nextPrayerId: nextPrayer.id,
    scheduledAtUtc: nextPrayer.scheduledAtUtc.subtract(
      const Duration(hours: 1),
    ),
  ));

  @override
  Future<void> scheduleFridayPrayerReminder({
    required DateTime firstReminderAtUtc,
    required String timezoneId,
    required int hoursBefore,
    required String languageCode,
  }) async {}
}
