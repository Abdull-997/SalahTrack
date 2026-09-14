import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_times_repository.dart';
import 'package:salah_focus/features/ramadan/application/ramadan_notification_planner.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_settings.dart';

class RamadanReminderCoordinator {
  RamadanReminderCoordinator(this._repository, this._planner);

  final PrayerTimesRepository _repository;
  final RamadanNotificationPlanner _planner;

  Future<void> reschedule(
    PrayerDay? today,
    RamadanSettings settings, {
    required DateTime nowUtc,
    required String languageCode,
  }) async {
    final List<PrayerDay> days = <PrayerDay>[];
    if (today != null) {
      final DateTime localDate = DateTime.parse(today.localDate);
      for (int offset = 0; offset <= 4; offset++) {
        final PrayerDay? day = await _repository.day(
          _iso(localDate.add(Duration(days: offset))),
        );
        if (day != null) days.add(day);
      }
    }
    await _planner.reschedule(
      settings,
      days,
      nowUtc: nowUtc,
      languageCode: languageCode,
    );
  }

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
