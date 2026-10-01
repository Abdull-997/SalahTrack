import 'package:salah_focus/features/prayer_times/domain/prayer_type.dart';
import 'package:salah_focus/features/prayer_times/domain/friday_prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/reminder_exception.dart';

enum AsrMadhhab { standard, hanafi }

enum HighLatitudeRule { middleOfNight, oneSeventh, angleBased }

class PrayerSettings {
  const PrayerSettings({
    this.calculationMethodId = 3,
    this.madhhab = AsrMadhhab.standard,
    this.highLatitudeRule = HighLatitudeRule.angleBased,
    this.gracePeriodMinutes = 15,
    this.snoozeMinutes = 20,
    this.maxSnoozes = 2,
    this.softReminderAfterSkip = true,
    this.confirmationText = 'Ich habe gebetet',
    this.adjustments = const <PrayerType, int>{},
    this.fridayPrayer = const FridayPrayerSettings(),
    this.reminderExceptions = const <ReminderException>[],
  });

  final int calculationMethodId;
  final AsrMadhhab madhhab;
  final HighLatitudeRule highLatitudeRule;
  final int gracePeriodMinutes;
  final int snoozeMinutes;
  final int? maxSnoozes;
  final bool softReminderAfterSkip;
  final String confirmationText;
  final Map<PrayerType, int> adjustments;
  final FridayPrayerSettings fridayPrayer;
  final List<ReminderException> reminderExceptions;

  bool remindersDisabledFor(PrayerType prayer, String localDate) =>
      reminderExceptions.any(
        (ReminderException exception) =>
            exception.prayer == prayer && exception.appliesTo(localDate),
      );

  static const Map<String, String> _defaultConfirmationTexts = <String, String>{
    'bn': 'আমি নামাজ পড়েছি',
    'fa': 'من نماز خوانده‌ام',
    'fr': "J'ai prié",
    'es': 'He rezado',
    'ha': 'Na yi sallah',
    'id': 'Saya telah salat',
    'jv': 'Aku wis shalat',
    'ms': 'Saya sudah solat',
    'pa': 'میں نماز پڑھ لئی اے',
    'nl': 'Ik heb gebeden',
    'ru': 'Я помолился',
    'so': 'Waan tukaday',
    'sw': 'Nimeswali',
    'ce': 'Ас салат диллина',
    'tr': 'Namaz kıldım',
    'de': 'Ich habe gebetet',
    'en': 'I have prayed',
    'ar': 'لقد صليت',
    'ur': 'میں نے نماز پڑھی ہے',
    'ps': 'ما لمونځ کړی دی',
  };

  static String defaultConfirmationText(String languageCode) =>
      _defaultConfirmationTexts[languageCode] ??
      _defaultConfirmationTexts['de']!;

  bool get usesDefaultConfirmationText =>
      _defaultConfirmationTexts.values.contains(confirmationText);

  int adjustmentFor(PrayerType type) {
    final int value = adjustments[type] ?? 0;
    if (value < -60) return -60;
    if (value > 60) return 60;
    return value;
  }

  PrayerSettings copyWith({
    int? calculationMethodId,
    AsrMadhhab? madhhab,
    HighLatitudeRule? highLatitudeRule,
    int? gracePeriodMinutes,
    int? snoozeMinutes,
    int? maxSnoozes,
    bool clearMaxSnoozes = false,
    bool? softReminderAfterSkip,
    String? confirmationText,
    Map<PrayerType, int>? adjustments,
    FridayPrayerSettings? fridayPrayer,
    List<ReminderException>? reminderExceptions,
  }) {
    return PrayerSettings(
      calculationMethodId: calculationMethodId ?? this.calculationMethodId,
      madhhab: madhhab ?? this.madhhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      maxSnoozes: clearMaxSnoozes ? null : maxSnoozes ?? this.maxSnoozes,
      softReminderAfterSkip:
          softReminderAfterSkip ?? this.softReminderAfterSkip,
      confirmationText: confirmationText ?? this.confirmationText,
      adjustments: adjustments ?? this.adjustments,
      fridayPrayer: fridayPrayer ?? this.fridayPrayer,
      reminderExceptions: reminderExceptions ?? this.reminderExceptions,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'calculationMethodId': calculationMethodId,
    'madhhab': madhhab.name,
    'highLatitudeRule': highLatitudeRule.name,
    'gracePeriodMinutes': gracePeriodMinutes,
    'snoozeMinutes': snoozeMinutes,
    'maxSnoozes': maxSnoozes,
    'softReminderAfterSkip': softReminderAfterSkip,
    'confirmationText': confirmationText,
    'adjustments': <String, int>{
      for (final PrayerType type in PrayerType.values)
        type.name: adjustmentFor(type),
    },
    'fridayPrayer': fridayPrayer.toJson(),
    'reminderExceptions': <Map<String, Object?>>[
      for (final ReminderException exception in reminderExceptions)
        exception.toJson(),
    ],
  };

  factory PrayerSettings.fromJson(Map<String, Object?> json) {
    final Object? rawAdjustments = json['adjustments'];
    final Object? rawFridayPrayer = json['fridayPrayer'];
    final Object? rawExceptions = json['reminderExceptions'];
    final Map<PrayerType, ReminderException> exceptions =
        <PrayerType, ReminderException>{};
    if (rawExceptions is List) {
      for (final Object? raw in rawExceptions) {
        final ReminderException? exception = ReminderException.fromJson(raw);
        if (exception != null) exceptions[exception.prayer] = exception;
      }
    }
    final Map<PrayerType, int> adjustments = <PrayerType, int>{};
    if (rawAdjustments is Map) {
      for (final MapEntry<Object?, Object?> entry in rawAdjustments.entries) {
        if (entry.key is String && entry.value is num) {
          try {
            adjustments[PrayerType.values.byName(entry.key! as String)] =
                (entry.value! as num).toInt();
          } on ArgumentError {
            // Ignore unknown prayer keys from future app versions.
          }
        }
      }
    }
    final int rawMethod = (json['calculationMethodId'] as num?)?.toInt() ?? 3;
    final int rawGrace = (json['gracePeriodMinutes'] as num?)?.toInt() ?? 15;
    final int rawSnooze = (json['snoozeMinutes'] as num?)?.toInt() ?? 20;
    final int? rawMaxSnoozes = (json['maxSnoozes'] as num?)?.toInt();
    final String rawConfirmation =
        ((json['confirmationText'] as String?) ?? 'Ich habe gebetet').trim();
    return PrayerSettings(
      calculationMethodId: <int>{1, 2, 3, 4, 5, 13}.contains(rawMethod)
          ? rawMethod
          : 3,
      madhhab: _parseMadhhab(json['madhhab']),
      highLatitudeRule: _parseHighLatitudeRule(json['highLatitudeRule']),
      gracePeriodMinutes: _clampInt(rawGrace, 0, 120),
      snoozeMinutes: _clampInt(rawSnooze, 5, 30),
      maxSnoozes: rawMaxSnoozes == null ? null : _clampInt(rawMaxSnoozes, 1, 5),
      softReminderAfterSkip: (json['softReminderAfterSkip'] as bool?) ?? true,
      confirmationText: rawConfirmation.isEmpty
          ? 'Ich habe gebetet'
          : rawConfirmation.substring(
              0,
              rawConfirmation.length > 80 ? 80 : rawConfirmation.length,
            ),
      adjustments: adjustments,
      fridayPrayer: rawFridayPrayer is Map
          ? FridayPrayerSettings.fromJson(
              Map<String, Object?>.from(rawFridayPrayer),
            )
          : const FridayPrayerSettings(),
      reminderExceptions: exceptions.values.toList(growable: false),
    );
  }

  static int _clampInt(int value, int minimum, int maximum) {
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
  }

  static AsrMadhhab _parseMadhhab(Object? value) {
    for (final AsrMadhhab item in AsrMadhhab.values) {
      if (item.name == value) return item;
    }
    return AsrMadhhab.standard;
  }

  static HighLatitudeRule _parseHighLatitudeRule(Object? value) {
    for (final HighLatitudeRule item in HighLatitudeRule.values) {
      if (item.name == value) return item;
    }
    return HighLatitudeRule.angleBased;
  }

  int get apiSchool => madhhab == AsrMadhhab.hanafi ? 1 : 0;

  int get apiLatitudeAdjustmentMethod => switch (highLatitudeRule) {
    HighLatitudeRule.middleOfNight => 1,
    HighLatitudeRule.oneSeventh => 2,
    HighLatitudeRule.angleBased => 3,
  };
}
