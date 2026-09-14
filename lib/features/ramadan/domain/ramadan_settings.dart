class RamadanSettings {
  const RamadanSettings({
    this.enabled = true,
    this.suhurReminderEnabled = true,
    this.iftarReminderEnabled = true,
    this.tarawihTrackingEnabled = true,
    this.qiyamTrackingEnabled = false,
    this.suhurReminderMinutes = 30,
    this.iftarReminderMinutes = 30,
  });

  final bool enabled;
  final bool suhurReminderEnabled;
  final bool iftarReminderEnabled;
  final bool tarawihTrackingEnabled;
  final bool qiyamTrackingEnabled;
  final int suhurReminderMinutes;
  final int iftarReminderMinutes;

  RamadanSettings copyWith({
    bool? enabled,
    bool? suhurReminderEnabled,
    bool? iftarReminderEnabled,
    bool? tarawihTrackingEnabled,
    bool? qiyamTrackingEnabled,
    int? suhurReminderMinutes,
    int? iftarReminderMinutes,
  }) => RamadanSettings(
    enabled: enabled ?? this.enabled,
    suhurReminderEnabled: suhurReminderEnabled ?? this.suhurReminderEnabled,
    iftarReminderEnabled: iftarReminderEnabled ?? this.iftarReminderEnabled,
    tarawihTrackingEnabled:
        tarawihTrackingEnabled ?? this.tarawihTrackingEnabled,
    qiyamTrackingEnabled: qiyamTrackingEnabled ?? this.qiyamTrackingEnabled,
    suhurReminderMinutes: suhurReminderMinutes ?? this.suhurReminderMinutes,
    iftarReminderMinutes: iftarReminderMinutes ?? this.iftarReminderMinutes,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'enabled': enabled,
    'suhurReminderEnabled': suhurReminderEnabled,
    'iftarReminderEnabled': iftarReminderEnabled,
    'tarawihTrackingEnabled': tarawihTrackingEnabled,
    'qiyamTrackingEnabled': qiyamTrackingEnabled,
    'suhurReminderMinutes': suhurReminderMinutes,
    'iftarReminderMinutes': iftarReminderMinutes,
  };

  factory RamadanSettings.fromJson(Map<String, Object?> json) {
    int reminderMinutes(String key) {
      final int value = (json[key] as num?)?.round() ?? 30;
      return value.clamp(5, 120);
    }

    return RamadanSettings(
      enabled: json['enabled'] as bool? ?? true,
      suhurReminderEnabled: json['suhurReminderEnabled'] as bool? ?? true,
      iftarReminderEnabled: json['iftarReminderEnabled'] as bool? ?? true,
      tarawihTrackingEnabled: json['tarawihTrackingEnabled'] as bool? ?? true,
      qiyamTrackingEnabled: json['qiyamTrackingEnabled'] as bool? ?? false,
      suhurReminderMinutes: reminderMinutes('suhurReminderMinutes'),
      iftarReminderMinutes: reminderMinutes('iftarReminderMinutes'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RamadanSettings &&
      enabled == other.enabled &&
      suhurReminderEnabled == other.suhurReminderEnabled &&
      iftarReminderEnabled == other.iftarReminderEnabled &&
      tarawihTrackingEnabled == other.tarawihTrackingEnabled &&
      qiyamTrackingEnabled == other.qiyamTrackingEnabled &&
      suhurReminderMinutes == other.suhurReminderMinutes &&
      iftarReminderMinutes == other.iftarReminderMinutes;

  @override
  int get hashCode => Object.hash(
    enabled,
    suhurReminderEnabled,
    iftarReminderEnabled,
    tarawihTrackingEnabled,
    qiyamTrackingEnabled,
    suhurReminderMinutes,
    iftarReminderMinutes,
  );
}
