import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/notifications/friday_prayer_reminder_planner.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/features/prayer_times/domain/friday_prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';

typedef _ScheduledFridayReminder = ({
  String localDate,
  DateTime reminderAtUtc,
  String timezoneId,
  String languageCode,
});

class _Notifications implements NotificationService {
  final List<_ScheduledFridayReminder> fridayReminders =
      <_ScheduledFridayReminder>[];
  int cancellations = 0;
  bool allowed = true;
  Completer<void>? firstScheduleStarted;
  Completer<void>? firstScheduleGate;
  int scheduleCalls = 0;

  @override
  Future<void> cancelAllFridayPrayerNotifications() async {
    cancellations++;
    fridayReminders.clear();
  }

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<void> scheduleFridayPrayerReminder({
    required String localDate,
    required DateTime reminderAtUtc,
    required String timezoneId,
    required String languageCode,
  }) async {
    scheduleCalls++;
    if (scheduleCalls == 1 && firstScheduleGate != null) {
      firstScheduleStarted?.complete();
      await firstScheduleGate!.future;
    }
    fridayReminders.add((
      localDate: localDate,
      reminderAtUtc: reminderAtUtc,
      timezoneId: timezoneId,
      languageCode: languageCode,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PrayerEntry _dhuhr(String date, int hour, int minute) {
  final int day = int.parse(date.substring(8));
  return PrayerEntry(
    id: '$date-dhuhr',
    localDate: date,
    type: PrayerType.dhuhr,
    scheduledAtUtc: DateTime.utc(2026, 9, day, hour, minute),
    timezoneId: 'UTC',
    graceEndsAtUtc: DateTime.utc(
      2026,
      9,
      day,
      hour,
      minute,
    ).add(const Duration(minutes: 15)),
    trackingEndsAtUtc: DateTime.utc(2026, 9, day, 23),
    status: PrayerStatus.pending,
  );
}

void main() {
  const FridayPrayerSettings automatic = FridayPrayerSettings(enabled: true);
  const FridayPrayerSettings manual1330 = FridayPrayerSettings(
    enabled: true,
    manualMinutesFromMidnight: 13 * 60 + 30,
  );

  test(
    'automatic Jumuah uses each Friday Dhuhr and schedules one hour early',
    () async {
      final _Notifications notifications = _Notifications();
      final FridayPrayerReminderPlanner planner = FridayPrayerReminderPlanner(
        notifications,
      );

      await planner.reschedule(
        automatic,
        fridayDhuhrEntries: <PrayerEntry>[
          _dhuhr('2026-09-18', 13, 28),
          _dhuhr('2026-09-25', 13, 20),
        ],
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 9, 14, 10),
      );

      expect(notifications.cancellations, 1);
      expect(
        notifications.fridayReminders.map((item) => item.reminderAtUtc),
        <DateTime>[
          DateTime.utc(2026, 9, 18, 12, 28),
          DateTime.utc(2026, 9, 25, 12, 20),
        ],
      );
    },
  );

  test('13:30 and 12:45 manual Jumuah schedule at 12:30 and 11:45', () async {
    final _Notifications notifications = _Notifications();
    final FridayPrayerReminderPlanner planner = FridayPrayerReminderPlanner(
      notifications,
    );
    final List<PrayerEntry> entries = <PrayerEntry>[
      _dhuhr('2026-09-18', 13, 28),
    ];

    await planner.reschedule(
      manual1330,
      fridayDhuhrEntries: entries,
      languageCode: 'en',
      nowUtc: DateTime.utc(2026, 9, 14, 10),
    );
    expect(
      notifications.fridayReminders.single.reminderAtUtc,
      DateTime.utc(2026, 9, 18, 12, 30),
    );

    await planner.reschedule(
      const FridayPrayerSettings(
        enabled: true,
        manualMinutesFromMidnight: 12 * 60 + 45,
      ),
      fridayDhuhrEntries: entries,
      languageCode: 'en',
      nowUtc: DateTime.utc(2026, 9, 14, 10),
    );
    expect(
      notifications.fridayReminders.single.reminderAtUtc,
      DateTime.utc(2026, 9, 18, 11, 45),
    );
  });

  test(
    'disable cancels and re-enable schedules exactly one reminder per Friday',
    () async {
      final _Notifications notifications = _Notifications();
      final FridayPrayerReminderPlanner planner = FridayPrayerReminderPlanner(
        notifications,
      );
      final PrayerEntry entry = _dhuhr('2026-09-18', 13, 28);

      await planner.reschedule(
        automatic,
        fridayDhuhrEntries: <PrayerEntry>[entry],
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 9, 14, 10),
      );
      await planner.reschedule(
        const FridayPrayerSettings(),
        fridayDhuhrEntries: <PrayerEntry>[entry],
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 9, 14, 10),
      );
      expect(notifications.fridayReminders, isEmpty);

      await planner.reschedule(
        automatic,
        fridayDhuhrEntries: <PrayerEntry>[entry, entry],
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 9, 14, 10),
      );
      expect(notifications.cancellations, 3);
      expect(notifications.fridayReminders, hasLength(1));
    },
  );

  test('rapid changes cannot restore an older schedule', () async {
    final _Notifications notifications = _Notifications()
      ..firstScheduleStarted = Completer<void>()
      ..firstScheduleGate = Completer<void>();
    final FridayPrayerReminderPlanner planner = FridayPrayerReminderPlanner(
      notifications,
    );
    final List<PrayerEntry> entries = <PrayerEntry>[
      _dhuhr('2026-09-18', 13, 28),
    ];
    final Future<void> oldSchedule = planner.reschedule(
      manual1330,
      fridayDhuhrEntries: entries,
      languageCode: 'en',
      nowUtc: DateTime.utc(2026, 9, 14, 10),
    );
    await notifications.firstScheduleStarted!.future;
    final Future<void> newSchedule = planner.reschedule(
      const FridayPrayerSettings(
        enabled: true,
        manualMinutesFromMidnight: 15 * 60,
      ),
      fridayDhuhrEntries: entries,
      languageCode: 'en',
      nowUtc: DateTime.utc(2026, 9, 14, 10),
    );
    notifications.firstScheduleGate!.complete();
    await Future.wait(<Future<void>>[oldSchedule, newSchedule]);

    expect(
      notifications.fridayReminders.single.reminderAtUtc,
      DateTime.utc(2026, 9, 18, 14),
    );
  });
}
