class FridayPrayerSettings {
  const FridayPrayerSettings({
    this.enabled = false,
    this.manualMinutesFromMidnight,
  });

  final bool enabled;

  /// A mosque-provided local Friday Prayer time. When null, the calculated
  /// Dhuhr time for each Friday remains the source of truth.
  final int? manualMinutesFromMidnight;

  bool get usesDhuhrTime => manualMinutesFromMidnight == null;

  int effectiveMinutesFromMidnight(int dhuhrMinutesFromMidnight) =>
      manualMinutesFromMidnight ?? dhuhrMinutesFromMidnight;

  FridayPrayerSettings copyWith({
    bool? enabled,
    int? manualMinutesFromMidnight,
    bool useDhuhrTime = false,
  }) => FridayPrayerSettings(
    enabled: enabled ?? this.enabled,
    manualMinutesFromMidnight: useDhuhrTime
        ? null
        : manualMinutesFromMidnight ?? this.manualMinutesFromMidnight,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'enabled': enabled,
    'manualMinutesFromMidnight': manualMinutesFromMidnight,
  };

  factory FridayPrayerSettings.fromJson(Map<String, Object?> json) {
    int? manualMinutes = (json['manualMinutesFromMidnight'] as num?)?.toInt();
    if (!json.containsKey('manualMinutesFromMidnight')) {
      // Legacy builds always serialized the old 13:30 placeholder, even when
      // the user never edited it. Treat that placeholder as "automatic" while
      // preserving every distinguishable mosque-specific legacy value.
      final int? legacyMinutes = (json['minutesFromMidnight'] as num?)?.toInt();
      if (legacyMinutes != null && legacyMinutes != 13 * 60 + 30) {
        manualMinutes = legacyMinutes;
      }
    }
    return FridayPrayerSettings(
      enabled: (json['enabled'] as bool?) ?? false,
      manualMinutesFromMidnight: manualMinutes?.clamp(0, 24 * 60 - 1),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FridayPrayerSettings &&
          enabled == other.enabled &&
          manualMinutesFromMidnight == other.manualMinutesFromMidnight;

  @override
  int get hashCode => Object.hash(enabled, manualMinutesFromMidnight);
}
