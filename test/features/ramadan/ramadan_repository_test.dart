import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/database/app_database.dart';
import 'package:salah_focus/features/ramadan/data/ramadan_repository.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_record.dart';
import 'package:sqflite/sqflite.dart';

class _FakeDatabase implements Database {
  final Map<String, Map<String, Object?>> records =
      <String, Map<String, Object?>>{};
  final Map<String, Map<String, Object?>> goals =
      <String, Map<String, Object?>>{};
  final Map<String, Map<String, Object?>> completions =
      <String, Map<String, Object?>>{};

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    if (table == 'ramadan_daily_records') {
      records[values['local_date']! as String] = Map<String, Object?>.from(
        values,
      );
    } else if (table == 'ramadan_goals') {
      goals[values['id']! as String] = Map<String, Object?>.from(values);
    } else if (table == 'ramadan_goal_completions') {
      completions['${values['goal_id']! as String}|${values['local_date']! as String}'] =
          Map<String, Object?>.from(values);
    }
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    Iterable<Map<String, Object?>> rows;
    if (table == 'ramadan_daily_records') {
      rows = records.values;
      if (where == 'local_date = ?') {
        rows = rows.where((row) => row['local_date'] == whereArgs!.first);
      } else if (where == 'hijri_year = ?') {
        rows = rows.where((row) => row['hijri_year'] == whereArgs!.first);
      }
      if (orderBy != null) {
        rows = rows.toList()
          ..sort(
            (a, b) =>
                (a['hijri_day']! as int).compareTo(b['hijri_day']! as int),
          );
      }
    } else if (table == 'ramadan_goals') {
      rows = goals.values.where((row) => row['archived_at_utc'] == null);
    } else {
      rows = completions.values.where(
        (row) => row['local_date'] == whereArgs!.first,
      );
    }
    if (columns != null) {
      rows = rows.map(
        (row) => <String, Object?>{
          for (final String column in columns) column: row[column],
        },
      );
    }
    return rows.map(Map<String, Object?>.from).toList(growable: false);
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final String id = whereArgs!.first! as String;
    final Map<String, Object?>? row = goals[id];
    if (row == null) return 0;
    row.addAll(values);
    return 1;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (table == 'ramadan_goal_completions') {
      return completions.remove('${whereArgs![0]}|${whereArgs[1]}') == null
          ? 0
          : 1;
    }
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'fasting, Tarawih, and Qiyam records persist and remain editable',
    () async {
      final _FakeDatabase database = _FakeDatabase();
      final RamadanRepository repository = RamadanRepository(
        AppDatabase(database),
      );
      final DateTime now = DateTime.utc(2027, 2, 19, 20);
      const RamadanRecord initial = RamadanRecord(
        localDate: '2027-02-19',
        hijriYear: 1448,
        hijriDay: 12,
        fastingStatus: FastingStatus.fasted,
        tarawihCompleted: true,
      );

      await repository.saveRecord(initial, now);
      await repository.saveRecord(
        initial.copyWith(
          fastingStatus: FastingStatus.didNotFast,
          qiyamCompleted: true,
        ),
        now.add(const Duration(hours: 1)),
      );

      final RamadanRecord? restored = await repository.recordForDate(
        initial.localDate,
      );
      expect(restored?.fastingStatus, FastingStatus.didNotFast);
      expect(restored?.tarawihCompleted, isTrue);
      expect(restored?.qiyamCompleted, isTrue);
      expect(await repository.recordsForHijriYear(1448), hasLength(1));
    },
  );

  test('goals can be added, edited, completed, and archived', () async {
    final _FakeDatabase database = _FakeDatabase();
    final RamadanRepository repository = RamadanRepository(
      AppDatabase(database),
    );
    final DateTime now = DateTime.utc(2027, 2, 19, 12);

    final goal = await repository.addGoal('Read Quran', now);
    await repository.updateGoal(goal, 'Read 5 pages');
    final updated = (await repository.activeGoals()).single;
    expect(updated.title, 'Read 5 pages');

    await repository.setGoalCompleted(
      goal: updated,
      localDate: '2027-02-19',
      completed: true,
      nowUtc: now,
    );
    expect(await repository.completedGoalIdsForDate('2027-02-19'), <String>{
      goal.id,
    });

    await repository.archiveGoal(updated, now);
    expect(await repository.activeGoals(), isEmpty);
    expect(
      await repository.completedGoalIdsForDate('2027-02-19'),
      contains(goal.id),
      reason: 'Archiving a goal must not erase its daily history.',
    );
  });
}
