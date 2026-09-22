import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/features/prayer_times/data/prayer_times_repository_impl.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_state_machine.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';

void main() {
  final DateTime scheduled = DateTime.utc(2026, 9, 18, 13, 28);
  final DateTime trackingEnd = DateTime.utc(2026, 9, 18, 16, 51);

  test(
    'fresh grace default schedules the future grace boundary at 15 minutes',
    () {
      final PrayerSettings settings = PrayerSettings();
      final DateTime graceEnd = PrayerTimesRepositoryImpl.calculateGraceEnd(
        scheduledAtUtc: scheduled,
        trackingEndsAtUtc: trackingEnd,
        gracePeriodMinutes: settings.gracePeriodMinutes,
      );
      expect(graceEnd, scheduled.add(const Duration(minutes: 15)));
    },
  );

  test(
    'a changed grace period affects newly scheduled reminder boundaries',
    () {
      const PrayerSettings settings = PrayerSettings(gracePeriodMinutes: 45);
      final DateTime graceEnd = PrayerTimesRepositoryImpl.calculateGraceEnd(
        scheduledAtUtc: scheduled,
        trackingEndsAtUtc: trackingEnd,
        gracePeriodMinutes: settings.gracePeriodMinutes,
      );
      expect(graceEnd, scheduled.add(const Duration(minutes: 45)));
    },
  );

  test('a changed snooze duration affects the next snooze schedule', () {
    const PrayerSettings settings = PrayerSettings(snoozeMinutes: 25);
    final DateTime now = scheduled.add(const Duration(hours: 1));
    final PrayerEntry prayer = PrayerEntry(
      id: '2026-09-18:dhuhr',
      localDate: '2026-09-18',
      type: PrayerType.dhuhr,
      scheduledAtUtc: scheduled,
      timezoneId: 'UTC',
      graceEndsAtUtc: scheduled.add(const Duration(minutes: 15)),
      trackingEndsAtUtc: trackingEnd,
      status: PrayerStatus.pending,
    );
    final PrayerEntry snoozed = const PrayerStateMachine().snooze(
      prayer,
      now,
      Duration(minutes: settings.snoozeMinutes),
      maximumSnoozes: settings.maxSnoozes,
    );
    expect(snoozed.snoozedUntilUtc, now.add(const Duration(minutes: 25)));
  });
}
