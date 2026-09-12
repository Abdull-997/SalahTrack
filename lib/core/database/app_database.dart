import 'package:path/path.dart' as p;
import 'package:salah_focus/features/prayer_times/domain/prayer_entry.dart';
import 'package:sqflite/sqflite.dart';

class PrayerDayMeta {
  const PrayerDayMeta({
    required this.localDate,
    required this.timezoneId,
    this.hijriDate,
    this.sunriseUtc,
    this.sourceKey = '',
  });

  final String localDate;
  final String timezoneId;
  final String? hijriDate;
  final DateTime? sunriseUtc;
  final String sourceKey;
}

class AppDatabase {
  AppDatabase([this._database]);

  Database? _database;

  Future<Database> get database async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }
    final String root = await getDatabasesPath();
    final Database db = await openDatabase(
      p.join(root, 'salah_focus.db'),
      version: 4,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE prayer_day_meta ADD COLUMN source_key TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE prayer_entries ADD COLUMN edited_at_utc TEXT',
          );
        }
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE prayer_entries (
            id TEXT PRIMARY KEY,
            local_date TEXT NOT NULL,
            type TEXT NOT NULL,
            scheduled_at_utc TEXT NOT NULL,
            timezone_id TEXT NOT NULL,
            grace_ends_at_utc TEXT NOT NULL,
            tracking_ends_at_utc TEXT NOT NULL,
            status TEXT NOT NULL,
            confirmed_at_utc TEXT,
            edited_at_utc TEXT,
            snoozed_until_utc TEXT,
            snooze_count INTEGER NOT NULL DEFAULT 0,
            manual_offset_minutes INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_prayer_entries_date ON prayer_entries(local_date)',
        );
        await db.execute('''
          CREATE TABLE prayer_day_meta (
            local_date TEXT PRIMARY KEY,
            timezone_id TEXT NOT NULL,
            hijri_date TEXT,
            sunrise_utc TEXT,
            fetched_at_utc TEXT NOT NULL,
            source_key TEXT NOT NULL
          )
        ''');
      },
    );
    _database = db;
    return db;
  }

  Future<void> upsertPrayerEntries(List<PrayerEntry> entries) async {
    final Database db = await database;
    await db.transaction((Transaction tx) async {
      for (final PrayerEntry entry in entries) {
        final List<Map<String, Object?>> previous = await tx.query(
          'prayer_entries',
          columns: <String>[
            'status',
            'confirmed_at_utc',
            'edited_at_utc',
            'snoozed_until_utc',
            'snooze_count',
          ],
          where: 'id = ?',
          whereArgs: <Object?>[entry.id],
          limit: 1,
        );
        Map<String, Object?> row = entry.toMap();
        if (previous.isNotEmpty) {
          final Map<String, Object?> old = previous.first;
          // Schedule refreshes must preserve the user's edit history.
          row['edited_at_utc'] = old['edited_at_utc'];
          final String oldStatus = old['status']! as String;
          if (oldStatus == 'prayed' ||
              oldStatus == 'skipped' ||
              oldStatus == 'missed') {
            row = <String, Object?>{
              ...row,
              'status': oldStatus,
              'confirmed_at_utc': old['confirmed_at_utc'],
              'snoozed_until_utc': old['snoozed_until_utc'],
              'snooze_count': old['snooze_count'],
            };
          } else if (oldStatus == 'snoozed') {
            final String? oldSnoozeText = old['snoozed_until_utc'] as String?;
            final DateTime? oldSnooze = oldSnoozeText == null
                ? null
                : DateTime.tryParse(oldSnoozeText)?.toUtc();
            row = <String, Object?>{
              ...row,
              // Keep the user's snooze only while it is still valid under the
              // refreshed schedule. Location/grace changes must never revive
              // a reminder beyond the new prayer tracking window.
              if (oldSnooze != null &&
                  oldSnooze.isBefore(
                    entry.trackingEndsAtUtc,
                  )) ...<String, Object?>{
                'status': oldStatus,
                'snoozed_until_utc': oldSnoozeText,
              },
              'snooze_count': old['snooze_count'],
            };
          }
        }
        await tx.insert(
          'prayer_entries',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<PrayerEntry?> prayerEntryById(String id) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'prayer_entries',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : PrayerEntry.fromMap(rows.first);
  }

  Future<void> upsertPrayerEntry(PrayerEntry entry) async {
    final Database db = await database;
    await db.insert(
      'prayer_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PrayerEntry>> prayerEntriesForDate(String localDate) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'prayer_entries',
      where: 'local_date = ?',
      whereArgs: <Object?>[localDate],
      orderBy: 'scheduled_at_utc ASC',
    );
    return rows.map(PrayerEntry.fromMap).toList(growable: false);
  }

  Future<List<PrayerEntry>> prayerEntriesBetween(
    String startDate,
    String endDate,
  ) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'prayer_entries',
      where: 'local_date >= ? AND local_date <= ?',
      whereArgs: <Object?>[startDate, endDate],
      orderBy: 'local_date ASC, scheduled_at_utc ASC',
    );
    return rows.map(PrayerEntry.fromMap).toList(growable: false);
  }

  Future<void> upsertDayMeta({
    required String localDate,
    required String timezoneId,
    required String? hijriDate,
    required DateTime? sunriseUtc,
    required String sourceKey,
  }) async {
    final Database db = await database;
    await db.insert('prayer_day_meta', <String, Object?>{
      'local_date': localDate,
      'timezone_id': timezoneId,
      'hijri_date': hijriDate,
      'sunrise_utc': sunriseUtc?.toIso8601String(),
      'fetched_at_utc': DateTime.now().toUtc().toIso8601String(),
      'source_key': sourceKey,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PrayerDayMeta?> dayMeta(String localDate) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'prayer_day_meta',
      where: 'local_date = ?',
      whereArgs: <Object?>[localDate],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final Map<String, Object?> row = rows.first;
    return PrayerDayMeta(
      localDate: row['local_date']! as String,
      timezoneId: row['timezone_id']! as String,
      hijriDate: row['hijri_date'] as String?,
      sunriseUtc: row['sunrise_utc'] == null
          ? null
          : DateTime.parse(row['sunrise_utc']! as String).toUtc(),
      sourceKey: (row['source_key'] as String?) ?? '',
    );
  }

  Future<bool> hasMonth(int year, int month, String sourceKey) async {
    final Database db = await database;
    final String prefix = '$year-${month.toString().padLeft(2, '0')}-%';
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM prayer_day_meta '
      'WHERE local_date LIKE ? AND source_key = ?',
      <Object?>[prefix, sourceKey],
    );
    return ((rows.first['count'] as int?) ?? 0) >= 27;
  }

  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
    }
    _database = null;
  }
}
