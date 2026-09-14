import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/notifications/notification_service.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/ramadan/application/ramadan_notification_planner.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_settings.dart';

typedef _Reminder = ({
  RamadanReminderKind kind,
  String localDate,
  DateTime reminderAtUtc,
  int minutesBefore,
});

class _Notifications implements NotificationService {
  final List<_Reminder> reminders = <_Reminder>[];
  int cancellations = 0;
  bool allowed = true;

  @override
  Future<void> cancelAllRamadanNotifications() async {
    cancellations++;
    reminders.clear();
  }

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<void> scheduleRamadanReminder({
    required RamadanReminderKind kind,
    required String localDate,
    required DateTime reminderAtUtc,
    required String timezoneId,
    required int minutesBefore,
    required String languageCode,
  }) async {
    reminders.add((
      kind: kind,
      localDate: localDate,
      reminderAtUtc: reminderAtUtc,
      minutesBefore: minutesBefore,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('schedules Suhur from adjusted Fajr and Iftar from Maghrib', () async {
    final _Notifications notifications = _Notifications();
    final RamadanNotificationPlanner planner = RamadanNotificationPlanner(
      notifications,
    );
    final PrayerDay day = _day(
      localDate: '2027-02-19',
      hijriDay: 12,
      hijriMonth: 9,
      fajrUtc: DateTime.utc(2027, 2, 19, 5, 17),
      maghribUtc: DateTime.utc(2027, 2, 19, 19, 42),
    );

    await planner.reschedule(
      const RamadanSettings(suhurReminderMinutes: 30, iftarReminderMinutes: 15),
      <PrayerDay>[day],
      nowUtc: DateTime.utc(2027, 2, 19, 1),
      languageCode: 'en',
    );

    expect(notifications.cancellations, 1);
    expect(notifications.reminders, hasLength(2));
    expect(notifications.reminders.first, (
      kind: RamadanReminderKind.suhur,
      localDate: '2027-02-19',
      reminderAtUtc: DateTime.utc(2027, 2, 19, 4, 47),
      minutesBefore: 30,
    ));
    expect(notifications.reminders.last, (
      kind: RamadanReminderKind.iftar,
      localDate: '2027-02-19',
      reminderAtUtc: DateTime.utc(2027, 2, 19, 19, 27),
      minutesBefore: 15,
    ));
  });

  test('outside Ramadan cancels and schedules no Ramadan reminders', () async {
    final _Notifications notifications = _Notifications();
    final RamadanNotificationPlanner planner = RamadanNotificationPlanner(
      notifications,
    );

    await planner.reschedule(
      const RamadanSettings(),
      <PrayerDay>[
        _day(
          localDate: '2026-09-14',
          hijriDay: 2,
          hijriMonth: 4,
          fajrUtc: DateTime.utc(2026, 9, 14, 4),
          maghribUtc: DateTime.utc(2026, 9, 14, 18),
        ),
      ],
      nowUtc: DateTime.utc(2026, 9, 14),
      languageCode: 'de',
    );

    expect(notifications.cancellations, 1);
    expect(notifications.reminders, isEmpty);
  });

  test('master switch off cancels reminders without scheduling', () async {
    final _Notifications notifications = _Notifications();
    final RamadanNotificationPlanner planner = RamadanNotificationPlanner(
      notifications,
    );
    final PrayerDay day = _day(
      localDate: '2027-02-19',
      hijriDay: 12,
      hijriMonth: 9,
      fajrUtc: DateTime.utc(2027, 2, 19, 5),
      maghribUtc: DateTime.utc(2027, 2, 19, 19),
    );

    await planner.reschedule(
      const RamadanSettings(enabled: false),
      <PrayerDay>[day],
      nowUtc: DateTime.utc(2027, 2, 19),
      languageCode: 'en',
    );

    expect(notifications.cancellations, 1);
    expect(notifications.reminders, isEmpty);
  });

  test(
    'individual reminder switches and Ramadan day boundary are obeyed',
    () async {
      final _Notifications notifications = _Notifications();
      final RamadanNotificationPlanner planner = RamadanNotificationPlanner(
        notifications,
      );
      final PrayerDay ramadan = _day(
        localDate: '2027-03-08',
        hijriDay: 29,
        hijriMonth: 9,
        fajrUtc: DateTime.utc(2027, 3, 8, 5),
        maghribUtc: DateTime.utc(2027, 3, 8, 19),
      );
      final PrayerDay afterRamadan = _day(
        localDate: '2027-03-09',
        hijriDay: 1,
        hijriMonth: 10,
        fajrUtc: DateTime.utc(2027, 3, 9, 5),
        maghribUtc: DateTime.utc(2027, 3, 9, 19),
      );

      await planner.reschedule(
        const RamadanSettings(suhurReminderEnabled: false),
        <PrayerDay>[ramadan, afterRamadan],
        nowUtc: DateTime.utc(2027, 3, 8),
        languageCode: 'en',
      );

      expect(notifications.reminders, hasLength(1));
      expect(notifications.reminders.single.kind, RamadanReminderKind.iftar);
      expect(notifications.reminders.single.localDate, ramadan.localDate);
    },
  );

  test('past informational reminders are not scheduled', () async {
    final _Notifications notifications = _Notifications();
    final RamadanNotificationPlanner planner = RamadanNotificationPlanner(
      notifications,
    );
    final PrayerDay day = _day(
      localDate: '2027-02-19',
      hijriDay: 12,
      hijriMonth: 9,
      fajrUtc: DateTime.utc(2027, 2, 19, 5),
      maghribUtc: DateTime.utc(2027, 2, 19, 19),
    );

    await planner.reschedule(
      const RamadanSettings(),
      <PrayerDay>[day],
      nowUtc: DateTime.utc(2027, 2, 19, 12),
      languageCode: 'en',
    );

    expect(notifications.reminders, hasLength(1));
    expect(notifications.reminders.single.kind, RamadanReminderKind.iftar);
  });
}

PrayerDay _day({
  required String localDate,
  required int hijriDay,
  required int hijriMonth,
  required DateTime fajrUtc,
  required DateTime maghribUtc,
}) => PrayerDay(
  localDate: localDate,
  timezoneId: 'UTC',
  hijriDay: hijriDay,
  hijriMonth: hijriMonth,
  hijriYear: 1448,
  entries: <PrayerEntry>[
    _entry(localDate, PrayerType.fajr, fajrUtc),
    _entry(localDate, PrayerType.maghrib, maghribUtc),
  ],
);

PrayerEntry _entry(String localDate, PrayerType type, DateTime scheduled) =>
    PrayerEntry(
      id: '$localDate:${type.name}',
      localDate: localDate,
      type: type,
      scheduledAtUtc: scheduled,
      timezoneId: 'UTC',
      graceEndsAtUtc: scheduled.add(const Duration(minutes: 30)),
      trackingEndsAtUtc: scheduled.add(const Duration(hours: 3)),
      status: PrayerStatus.upcoming,
      manualOffsetMinutes: type == PrayerType.fajr ? 7 : 2,
    );
