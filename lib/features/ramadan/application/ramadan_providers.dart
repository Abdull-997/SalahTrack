import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_day.dart';
import 'package:salah_focus/features/ramadan/data/ramadan_repository.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_calendar.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_goal.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_record.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';

class RamadanTodayData {
  const RamadanTodayData({
    required this.prayerDay,
    required this.ramadanDate,
    required this.record,
    required this.goals,
    required this.completedGoalIds,
  });

  final PrayerDay prayerDay;
  final RamadanDate ramadanDate;
  final RamadanRecord record;
  final List<RamadanGoal> goals;
  final Set<String> completedGoalIds;
}

class RamadanTrackerData {
  const RamadanTrackerData({
    required this.today,
    required this.records,
    required this.goals,
    required this.completedGoalIds,
  });

  final RamadanTodayData today;
  final List<RamadanRecord> records;
  final List<RamadanGoal> goals;
  final Set<String> completedGoalIds;
}

final Provider<RamadanRepository> ramadanRepositoryProvider =
    Provider<RamadanRepository>(
      (Ref ref) => RamadanRepository(ref.watch(appDatabaseProvider)),
    );

final Provider<RamadanController> ramadanControllerProvider =
    Provider<RamadanController>(
      (Ref ref) => RamadanController(
        ref.watch(ramadanRepositoryProvider),
        () => ref.read(clockServiceProvider).nowUtc(),
      ),
    );

final FutureProvider<RamadanTodayData?> ramadanTodayProvider =
    FutureProvider<RamadanTodayData?>((Ref ref) async {
      final bool enabled = ref.watch(
        settingsControllerProvider.select(
          (preferences) => preferences.ramadanSettings.enabled,
        ),
      );
      if (!enabled) return null;

      final PrayerDay? day = await ref.watch(todayPrayerDayProvider.future);
      if (day == null) return null;
      final RamadanDate? ramadanDate = RamadanCalendar.dateFor(day);
      if (ramadanDate == null) return null;

      final RamadanRepository repository = ref.watch(ramadanRepositoryProvider);
      final RamadanRecord record =
          await repository.recordForDate(day.localDate) ??
          RamadanRecord(
            localDate: day.localDate,
            hijriYear: ramadanDate.year,
            hijriDay: ramadanDate.day,
          );
      final List<RamadanGoal> goals = await repository.activeGoals();
      final Set<String> completed = await repository.completedGoalIdsForDate(
        day.localDate,
      );
      return RamadanTodayData(
        prayerDay: day,
        ramadanDate: ramadanDate,
        record: record,
        goals: goals,
        completedGoalIds: completed,
      );
    });

final FutureProvider<RamadanTrackerData?> ramadanTrackerDataProvider =
    FutureProvider<RamadanTrackerData?>((Ref ref) async {
      final RamadanTodayData? today = await ref.watch(
        ramadanTodayProvider.future,
      );
      if (today == null) return null;
      final RamadanRepository repository = ref.watch(ramadanRepositoryProvider);
      final List<RamadanRecord> records = await repository.recordsForHijriYear(
        today.ramadanDate.year,
      );
      return RamadanTrackerData(
        today: today,
        records: records,
        goals: today.goals,
        completedGoalIds: today.completedGoalIds,
      );
    });

class RamadanController {
  RamadanController(this._repository, this._nowUtc);

  final RamadanRepository _repository;
  final DateTime Function() _nowUtc;

  Future<void> setFasting(RamadanRecord record, FastingStatus status) =>
      _repository.saveRecord(record.copyWith(fastingStatus: status), _nowUtc());

  Future<void> saveRecord(RamadanRecord record) =>
      _repository.saveRecord(record, _nowUtc());

  Future<void> setTarawih(RamadanRecord record, bool? completed) =>
      _repository.saveRecord(
        record.copyWith(
          tarawihCompleted: completed,
          clearTarawih: completed == null,
        ),
        _nowUtc(),
      );

  Future<void> setQiyam(RamadanRecord record, bool? completed) =>
      _repository.saveRecord(
        record.copyWith(
          qiyamCompleted: completed,
          clearQiyam: completed == null,
        ),
        _nowUtc(),
      );

  Future<void> addGoal(String title) => _repository.addGoal(title, _nowUtc());

  Future<void> updateGoal(RamadanGoal goal, String title) =>
      _repository.updateGoal(goal, title);

  Future<void> deleteGoal(RamadanGoal goal) =>
      _repository.archiveGoal(goal, _nowUtc());

  Future<void> setGoalCompleted({
    required RamadanGoal goal,
    required String localDate,
    required bool completed,
  }) => _repository.setGoalCompleted(
    goal: goal,
    localDate: localDate,
    completed: completed,
    nowUtc: _nowUtc(),
  );
}
