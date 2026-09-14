import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/notifications/friday_prayer_reminder_planner.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/features/prayer_times/domain/friday_prayer_settings.dart';

typedef _ScheduledFridayReminder = ({
  DateTime firstReminderAtUtc,
  String timezoneId,
  int hoursBefore,
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
    required DateTime firstReminderAtUtc,
    required String timezoneId,
    required int hoursBefore,
    required String languageCode,
  }) async {
    scheduleCalls++;
    if (scheduleCalls == 1 && firstScheduleGate != null) {
      firstScheduleStarted?.complete();
      await firstScheduleGate!.future;
    }
    fridayReminders.add((
      firstReminderAtUtc: firstReminderAtUtc,
      timezoneId: timezoneId,
      hoursBefore: hoursBefore,
      languageCode: languageCode,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const FridayPrayerSettings enabled = FridayPrayerSettings(
    enabled: true,
    minutesFromMidnight: 13 * 60 + 30,
  );

  test(
    'schedules exactly two weekly Friday reminders one and two hours early',
    () async {
      final _Notifications notifications = _Notifications();
      final FridayPrayerReminderPlanner planner = FridayPrayerReminderPlanner(
        notifications,
      );

      await planner.reschedule(
        enabled,
        timezoneId: 'UTC',
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 9, 14, 10),
      );

      expect(notifications.cancellations, 1);
      expect(notifications.fridayReminders, hasLength(2));
      expect(
        notifications.fridayReminders.map((item) => item.hoursBefore),
        <int>[2, 1],
      );
      expect(
        notifications.fridayReminders.map((item) => item.firstReminderAtUtc),
        <DateTime>[
          DateTime.utc(2026, 9, 18, 11, 30),
          DateTime.utc(2026, 9, 18, 12, 30),
        ],
      );
      expect(
        notifications.fridayReminders.every(
          (item) => item.firstReminderAtUtc.weekday == DateTime.friday,
        ),
        isTrue,
      );
    },
  );

  test('disabling cancels both reminders and schedules nothing', () async {
    final _Notifications notifications = _Notifications();
    final FridayPrayerReminderPlanner planner = FridayPrayerReminderPlanner(
      notifications,
    );
    await planner.reschedule(
      enabled,
      timezoneId: 'UTC',
      languageCode: 'en',
      nowUtc: DateTime.utc(2026, 9, 14, 10),
    );

    await planner.reschedule(
      const FridayPrayerSettings(),
      timezoneId: 'UTC',
      languageCode: 'en',
      nowUtc: DateTime.utc(2026, 9, 14, 10),
    );

    expect(notifications.cancellations, 2);
    expect(notifications.fridayReminders, isEmpty);
  });

  test('changing the configured time replaces both reminders', () async {
    final _Notifications notifications = _Notifications();
    final FridayPrayerReminderPlanner planner = FridayPrayerReminderPlanner(
      notifications,
    );
    await planner.reschedule(
      enabled,
      timezoneId: 'UTC',
      languageCode: 'en',
      nowUtc: DateTime.utc(2026, 9, 14, 10),
    );

    await planner.reschedule(
      enabled.copyWith(minutesFromMidnight: 14 * 60),
      timezoneId: 'UTC',
      languageCode: 'de',
      nowUtc: DateTime.utc(2026, 9, 14, 10),
    );

    expect(notifications.cancellations, 2);
    expect(
      notifications.fridayReminders.map((item) => item.firstReminderAtUtc),
      <DateTime>[DateTime.utc(2026, 9, 18, 12), DateTime.utc(2026, 9, 18, 13)],
    );
    expect(
      notifications.fridayReminders.every((item) => item.languageCode == 'de'),
      isTrue,
    );
  });

  test(
    'rapid time changes cannot restore an older reminder schedule',
    () async {
      final _Notifications notifications = _Notifications()
        ..firstScheduleStarted = Completer<void>()
        ..firstScheduleGate = Completer<void>();
      final FridayPrayerReminderPlanner planner = FridayPrayerReminderPlanner(
        notifications,
      );
      final Future<void> oldSchedule = planner.reschedule(
        enabled,
        timezoneId: 'UTC',
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 9, 14, 10),
      );
      await notifications.firstScheduleStarted!.future;
      final Future<void> newSchedule = planner.reschedule(
        enabled.copyWith(minutesFromMidnight: 15 * 60),
        timezoneId: 'UTC',
        languageCode: 'en',
        nowUtc: DateTime.utc(2026, 9, 14, 10),
      );
      notifications.firstScheduleGate!.complete();

      await Future.wait(<Future<void>>[oldSchedule, newSchedule]);

      expect(notifications.cancellations, 2);
      expect(
        notifications.fridayReminders.map((item) => item.firstReminderAtUtc),
        <DateTime>[
          DateTime.utc(2026, 9, 18, 13),
          DateTime.utc(2026, 9, 18, 14),
        ],
      );
    },
  );
}
