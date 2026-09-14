import 'package:salah_focus/core/database/app_database.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_goal.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_record.dart';
import 'package:sqflite/sqflite.dart';

class RamadanRepository {
  RamadanRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<RamadanRecord?> recordForDate(String localDate) async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      'ramadan_daily_records',
      where: 'local_date = ?',
      whereArgs: <Object?>[localDate],
      limit: 1,
    );
    return rows.isEmpty ? null : RamadanRecord.fromMap(rows.first);
  }

  Future<List<RamadanRecord>> recordsForHijriYear(int hijriYear) async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      'ramadan_daily_records',
      where: 'hijri_year = ?',
      whereArgs: <Object?>[hijriYear],
      orderBy: 'hijri_day ASC',
    );
    return rows.map(RamadanRecord.fromMap).toList(growable: false);
  }

  Future<void> saveRecord(RamadanRecord record, DateTime nowUtc) async {
    final Database db = await _appDatabase.database;
    await db.insert(
      'ramadan_daily_records',
      record.toMap(nowUtc),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RamadanGoal>> activeGoals() async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      'ramadan_goals',
      where: 'archived_at_utc IS NULL',
      orderBy: 'created_at_utc ASC',
    );
    return rows.map(RamadanGoal.fromMap).toList(growable: false);
  }

  Future<RamadanGoal> addGoal(String title, DateTime nowUtc) async {
    final Database db = await _appDatabase.database;
    final String id = 'goal-${nowUtc.toUtc().microsecondsSinceEpoch}';
    final RamadanGoal goal = RamadanGoal(id: id, title: title.trim());
    await db.insert('ramadan_goals', <String, Object?>{
      'id': goal.id,
      'title': goal.title,
      'created_at_utc': nowUtc.toUtc().toIso8601String(),
      'archived_at_utc': null,
    });
    return goal;
  }

  Future<void> updateGoal(RamadanGoal goal, String title) async {
    final Database db = await _appDatabase.database;
    await db.update(
      'ramadan_goals',
      <String, Object?>{'title': title.trim()},
      where: 'id = ? AND archived_at_utc IS NULL',
      whereArgs: <Object?>[goal.id],
    );
  }

  Future<void> archiveGoal(RamadanGoal goal, DateTime nowUtc) async {
    final Database db = await _appDatabase.database;
    await db.update(
      'ramadan_goals',
      <String, Object?>{'archived_at_utc': nowUtc.toUtc().toIso8601String()},
      where: 'id = ?',
      whereArgs: <Object?>[goal.id],
    );
  }

  Future<Set<String>> completedGoalIdsForDate(String localDate) async {
    final Database db = await _appDatabase.database;
    final List<Map<String, Object?>> rows = await db.query(
      'ramadan_goal_completions',
      columns: <String>['goal_id'],
      where: 'local_date = ?',
      whereArgs: <Object?>[localDate],
    );
    return rows
        .map((Map<String, Object?> row) => row['goal_id']! as String)
        .toSet();
  }

  Future<void> setGoalCompleted({
    required RamadanGoal goal,
    required String localDate,
    required bool completed,
    required DateTime nowUtc,
  }) async {
    final Database db = await _appDatabase.database;
    if (!completed) {
      await db.delete(
        'ramadan_goal_completions',
        where: 'goal_id = ? AND local_date = ?',
        whereArgs: <Object?>[goal.id, localDate],
      );
      return;
    }
    await db.insert('ramadan_goal_completions', <String, Object?>{
      'goal_id': goal.id,
      'local_date': localDate,
      'completed_at_utc': nowUtc.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
