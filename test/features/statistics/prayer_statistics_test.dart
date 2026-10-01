import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/statistics/domain/prayer_statistics.dart';

final DateTime _now = DateTime.utc(2026, 10, 1, 12);

PrayerEntry _entry(
  String date,
  PrayerType type,
  PrayerStatus status, {
  int snoozes = 0,
  String? reason,
  int hour = 6,
}) {
  final DateTime scheduled = DateTime.utc(
    int.parse(date.substring(0, 4)),
    int.parse(date.substring(5, 7)),
    int.parse(date.substring(8, 10)),
    hour,
  );
  return PrayerEntry(
    id: '$date-${type.name}',
    localDate: date,
    type: type,
    scheduledAtUtc: scheduled,
    timezoneId: 'UTC',
    graceEndsAtUtc: scheduled.add(const Duration(minutes: 15)),
    trackingEndsAtUtc: scheduled.add(const Duration(hours: 5)),
    status: status,
    snoozeCount: snoozes,
    dismissReason: reason,
  );
}

PrayerStatistics _calculate(
  List<PrayerEntry> entries, {
  StatisticsRange range = StatisticsRange.allTime,
}) => PrayerStatistics.calculate(
  entries,
  nowUtc: _now,
  localToday: _now,
  range: range,
);

void main() {
  test('empty and upcoming history have safe zero percentages', () {
    final PrayerStatistics empty = _calculate(<PrayerEntry>[]);
    expect(empty.totalRecorded, 0);
    expect(empty.completion, 0);
    expect(empty.byPrayer[PrayerType.fajr]!.completion, 0);
    expect(empty.currentStreak, 0);
    expect(empty.bestStreak, 0);
    expect(empty.reasonCounts, isEmpty);
    final PrayerStatistics future = _calculate(<PrayerEntry>[
      _entry('2026-10-02', PrayerType.fajr, PrayerStatus.upcoming),
    ]);
    expect(future.totalRecorded, 0);
  });

  test(
    'per-prayer and overall completion use confirmed and unconfirmed history',
    () {
      final List<PrayerEntry> entries = <PrayerEntry>[
        for (final PrayerType type in PrayerType.values)
          _entry('2026-09-29', type, PrayerStatus.prayed),
        for (final PrayerType type in PrayerType.values)
          _entry(
            '2026-09-30',
            type,
            type.index < 2 ? PrayerStatus.prayed : PrayerStatus.missed,
          ),
        // This prayer is still in progress and must not lower the percentage.
        _entry('2026-10-01', PrayerType.fajr, PrayerStatus.pending, hour: 10),
      ];
      final PrayerStatistics stats = _calculate(entries);
      expect(stats.byPrayer[PrayerType.fajr]!.prayed, 2);
      expect(stats.byPrayer[PrayerType.fajr]!.notConfirmed, 0);
      expect(stats.byPrayer[PrayerType.maghrib]!.prayed, 1);
      expect(stats.byPrayer[PrayerType.maghrib]!.notConfirmed, 1);
      expect(stats.byPrayer[PrayerType.maghrib]!.completion, 0.5);
      expect(stats.totalPrayed, 7);
      expect(stats.totalNotConfirmed, 3);
      expect(stats.completion, 0.7);
      expect(stats.completeDays, 1);
      expect(stats.bestStreak, 1);
      expect(stats.currentStreak, 0);
    },
  );

  test('old pending entries count as unconfirmed after tracking ends', () {
    final PrayerStatistics stats = _calculate(<PrayerEntry>[
      _entry('2026-09-30', PrayerType.isha, PrayerStatus.snoozed, snoozes: 2),
      _entry('2026-09-30', PrayerType.asr, PrayerStatus.skipped),
    ]);
    expect(stats.totalNotConfirmed, 2);
    expect(stats.totalSnoozes, 2);
    expect(stats.stoppedReminders, 1);
  });

  test('range filters include today and handle month boundaries', () {
    final List<PrayerEntry> entries = <PrayerEntry>[
      _entry('2026-09-01', PrayerType.fajr, PrayerStatus.prayed),
      _entry('2026-09-20', PrayerType.dhuhr, PrayerStatus.prayed),
      _entry('2026-09-28', PrayerType.asr, PrayerStatus.prayed),
      _entry('2026-10-01', PrayerType.maghrib, PrayerStatus.prayed),
    ];
    expect(
      _calculate(entries, range: StatisticsRange.last7Days).totalPrayed,
      2,
    );
    expect(
      _calculate(entries, range: StatisticsRange.last30Days).totalPrayed,
      3,
    );
    expect(
      _calculate(entries, range: StatisticsRange.thisMonth).totalPrayed,
      1,
    );
    expect(_calculate(entries, range: StatisticsRange.allTime).totalPrayed, 4);
  });

  test('streaks count consecutive complete days through yesterday', () {
    final List<PrayerEntry> entries = <PrayerEntry>[
      for (final String date in <String>[
        '2026-09-27',
        '2026-09-28',
        '2026-09-30',
      ])
        for (final PrayerType type in PrayerType.values)
          _entry(date, type, PrayerStatus.prayed),
      _entry('2026-10-01', PrayerType.fajr, PrayerStatus.upcoming),
    ];
    final PrayerStatistics stats = _calculate(entries);
    expect(stats.completeDays, 3);
    expect(stats.bestStreak, 2);
    expect(stats.currentStreak, 1);
  });

  test('snoozes and stopped reminders group saved and missing reasons', () {
    final PrayerStatistics stats = _calculate(<PrayerEntry>[
      _entry('2026-09-30', PrayerType.maghrib, PrayerStatus.prayed, snoozes: 5),
      _entry(
        '2026-09-30',
        PrayerType.dhuhr,
        PrayerStatus.skipped,
        reason: 'At work',
      ),
      _entry(
        '2026-09-29',
        PrayerType.dhuhr,
        PrayerStatus.skipped,
        reason: 'At work',
      ),
      _entry('2026-09-30', PrayerType.asr, PrayerStatus.skipped),
    ]);
    expect(stats.totalSnoozes, 5);
    expect(stats.mostSnoozedPrayer, PrayerType.maghrib);
    expect(stats.stoppedReminders, 3);
    expect(stats.reasonCounts['At work'], 2);
    expect(stats.reasonCounts[''], 6);
    expect(stats.totalReasonActions, 8);
  });
}
