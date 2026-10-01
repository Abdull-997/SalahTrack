import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_status.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';

enum StatisticsRange {
  last7Days,
  last30Days,
  thisMonth,
  allTime;

  String? startDate(DateTime localToday) {
    final DateTime start = switch (this) {
      StatisticsRange.last7Days => DateTime(
        localToday.year,
        localToday.month,
        localToday.day - 6,
      ),
      StatisticsRange.last30Days => DateTime(
        localToday.year,
        localToday.month,
        localToday.day - 29,
      ),
      StatisticsRange.thisMonth => DateTime(localToday.year, localToday.month),
      StatisticsRange.allTime => DateTime(1),
    };
    if (this == StatisticsRange.allTime) return null;
    return _iso(start);
  }
}

class PrayerCount {
  const PrayerCount({this.prayed = 0, this.notConfirmed = 0});

  final int prayed;
  final int notConfirmed;

  int get total => prayed + notConfirmed;
  double get completion => total == 0 ? 0 : prayed / total;
}

class PrayerStatistics {
  const PrayerStatistics({
    required this.byPrayer,
    required this.snoozesByPrayer,
    required this.reasonCounts,
    required this.completeDays,
    required this.currentStreak,
    required this.bestStreak,
    required this.stoppedReminders,
  });

  final Map<PrayerType, PrayerCount> byPrayer;

  /// Number of recorded snooze actions, including prayers later confirmed.
  final Map<PrayerType, int> snoozesByPrayer;

  /// Empty string represents an action for which no reason was saved.
  final Map<String, int> reasonCounts;
  final int completeDays;
  final int currentStreak;
  final int bestStreak;
  final int stoppedReminders;

  int get totalPrayed =>
      byPrayer.values.fold(0, (sum, count) => sum + count.prayed);
  int get totalNotConfirmed =>
      byPrayer.values.fold(0, (sum, count) => sum + count.notConfirmed);
  int get totalRecorded => totalPrayed + totalNotConfirmed;
  double get completion => totalRecorded == 0 ? 0 : totalPrayed / totalRecorded;
  int get totalSnoozes =>
      snoozesByPrayer.values.fold(0, (sum, count) => sum + count);
  int get totalReasonActions => totalSnoozes + stoppedReminders;

  PrayerType? get mostSnoozedPrayer {
    PrayerType? best;
    int count = 0;
    for (final PrayerType type in PrayerType.values) {
      final int value = snoozesByPrayer[type] ?? 0;
      if (value > count) {
        best = type;
        count = value;
      }
    }
    return best;
  }

  static PrayerStatistics calculate(
    Iterable<PrayerEntry> entries, {
    required DateTime nowUtc,
    required DateTime localToday,
    required StatisticsRange range,
  }) {
    final String today = _iso(localToday);
    final String? first = range.startDate(localToday);
    final Map<PrayerType, int> prayed = <PrayerType, int>{};
    final Map<PrayerType, int> notConfirmed = <PrayerType, int>{};
    final Map<PrayerType, int> snoozes = <PrayerType, int>{};
    final Map<String, int> reasons = <String, int>{};
    final Map<String, Set<PrayerType>> completedByDay =
        <String, Set<PrayerType>>{};
    int stopped = 0;

    for (final PrayerEntry entry in entries) {
      if (entry.localDate.compareTo(today) > 0 ||
          (first != null && entry.localDate.compareTo(first) < 0)) {
        continue;
      }
      final int snoozeCount = entry.snoozeCount < 0 ? 0 : entry.snoozeCount;
      if (snoozeCount > 0) {
        snoozes.update(
          entry.type,
          (value) => value + snoozeCount,
          ifAbsent: () => snoozeCount,
        );
        reasons.update(
          '',
          (value) => value + snoozeCount,
          ifAbsent: () => snoozeCount,
        );
      }
      if (entry.status == PrayerStatus.skipped) {
        stopped++;
        final String reason = entry.dismissReason?.trim() ?? '';
        reasons.update(reason, (value) => value + 1, ifAbsent: () => 1);
      }

      final bool confirmed = entry.status == PrayerStatus.prayed;
      final bool unconfirmed =
          entry.status == PrayerStatus.missed ||
          entry.status == PrayerStatus.skipped ||
          (!entry.trackingEndsAtUtc.isAfter(nowUtc) && !confirmed);
      if (confirmed) {
        prayed.update(entry.type, (value) => value + 1, ifAbsent: () => 1);
        completedByDay
            .putIfAbsent(entry.localDate, () => <PrayerType>{})
            .add(entry.type);
      } else if (unconfirmed) {
        notConfirmed.update(
          entry.type,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final List<DateTime> completeDates =
        completedByDay.entries
            .where((entry) => entry.value.length == PrayerType.values.length)
            .map((entry) => DateTime.parse('${entry.key}T00:00:00Z'))
            .toList()
          ..sort();
    int bestStreak = 0;
    int run = 0;
    DateTime? previous;
    for (final DateTime date in completeDates) {
      run = previous != null && date.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > bestStreak) bestStreak = run;
      previous = date;
    }
    final Set<String> completeKeys = completeDates.map(_iso).toSet();
    DateTime cursor = DateTime.utc(
      localToday.year,
      localToday.month,
      localToday.day,
    );
    if (!completeKeys.contains(_iso(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    int currentStreak = 0;
    while (completeKeys.contains(_iso(cursor))) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return PrayerStatistics(
      byPrayer: <PrayerType, PrayerCount>{
        for (final PrayerType type in PrayerType.values)
          type: PrayerCount(
            prayed: prayed[type] ?? 0,
            notConfirmed: notConfirmed[type] ?? 0,
          ),
      },
      snoozesByPrayer: snoozes,
      reasonCounts: reasons,
      completeDays: completeDates.length,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      stoppedReminders: stopped,
    );
  }
}

String _iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
