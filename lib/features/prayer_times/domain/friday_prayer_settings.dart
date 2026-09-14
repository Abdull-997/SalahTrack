class FridayPrayerSettings {
  const FridayPrayerSettings({
    this.enabled = false,
    this.minutesFromMidnight = 13 * 60 + 30,
  });

  final bool enabled;

  /// The mosque-provided local Friday Prayer time.
  final int minutesFromMidnight;

  int get hour => minutesFromMidnight ~/ 60;
  int get minute => minutesFromMidnight % 60;

  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';

  FridayPrayerSettings copyWith({bool? enabled, int? minutesFromMidnight}) =>
      FridayPrayerSettings(
        enabled: enabled ?? this.enabled,
        minutesFromMidnight: minutesFromMidnight ?? this.minutesFromMidnight,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'enabled': enabled,
    'minutesFromMidnight': minutesFromMidnight,
  };

  factory FridayPrayerSettings.fromJson(Map<String, Object?> json) {
    final int rawMinutes =
        (json['minutesFromMidnight'] as num?)?.toInt() ?? 13 * 60 + 30;
    return FridayPrayerSettings(
      enabled: (json['enabled'] as bool?) ?? false,
      minutesFromMidnight: rawMinutes.clamp(0, 24 * 60 - 1),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FridayPrayerSettings &&
          enabled == other.enabled &&
          minutesFromMidnight == other.minutesFromMidnight;

  @override
  int get hashCode => Object.hash(enabled, minutesFromMidnight);
}
