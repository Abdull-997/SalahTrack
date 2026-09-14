enum FastingStatus { notRecorded, fasted, didNotFast }

class RamadanRecord {
  const RamadanRecord({
    required this.localDate,
    required this.hijriYear,
    required this.hijriDay,
    this.fastingStatus = FastingStatus.notRecorded,
    this.tarawihCompleted,
    this.qiyamCompleted,
  });

  final String localDate;
  final int hijriYear;
  final int hijriDay;
  final FastingStatus fastingStatus;

  /// Null means that the optional worship has not been recorded.
  final bool? tarawihCompleted;
  final bool? qiyamCompleted;

  RamadanRecord copyWith({
    FastingStatus? fastingStatus,
    bool? tarawihCompleted,
    bool clearTarawih = false,
    bool? qiyamCompleted,
    bool clearQiyam = false,
  }) => RamadanRecord(
    localDate: localDate,
    hijriYear: hijriYear,
    hijriDay: hijriDay,
    fastingStatus: fastingStatus ?? this.fastingStatus,
    tarawihCompleted: clearTarawih
        ? null
        : tarawihCompleted ?? this.tarawihCompleted,
    qiyamCompleted: clearQiyam ? null : qiyamCompleted ?? this.qiyamCompleted,
  );

  factory RamadanRecord.fromMap(Map<String, Object?> map) => RamadanRecord(
    localDate: map['local_date']! as String,
    hijriYear: map['hijri_year']! as int,
    hijriDay: map['hijri_day']! as int,
    fastingStatus: FastingStatus.values.byName(
      map['fasting_status']! as String,
    ),
    tarawihCompleted: _boolOrNull(map['tarawih_completed']),
    qiyamCompleted: _boolOrNull(map['qiyam_completed']),
  );

  Map<String, Object?> toMap(DateTime updatedAtUtc) => <String, Object?>{
    'local_date': localDate,
    'hijri_year': hijriYear,
    'hijri_day': hijriDay,
    'fasting_status': fastingStatus.name,
    'tarawih_completed': _intOrNull(tarawihCompleted),
    'qiyam_completed': _intOrNull(qiyamCompleted),
    'updated_at_utc': updatedAtUtc.toUtc().toIso8601String(),
  };

  static bool? _boolOrNull(Object? value) => value == null ? null : value == 1;
  static int? _intOrNull(bool? value) => value == null ? null : (value ? 1 : 0);
}
