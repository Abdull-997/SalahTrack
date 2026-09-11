enum PrayerType {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha;

  String get apiKey => switch (this) {
    PrayerType.fajr => 'Fajr',
    PrayerType.dhuhr => 'Dhuhr',
    PrayerType.asr => 'Asr',
    PrayerType.maghrib => 'Maghrib',
    PrayerType.isha => 'Isha',
  };

  String localizedName(String languageCode) {
    const Map<String, Map<PrayerType, String>> values = {
      'de': {
        PrayerType.fajr: 'Fajr',
        PrayerType.dhuhr: 'Dhuhr',
        PrayerType.asr: 'Asr',
        PrayerType.maghrib: 'Maghrib',
        PrayerType.isha: 'Isha',
      },
      'en': {
        PrayerType.fajr: 'Fajr',
        PrayerType.dhuhr: 'Dhuhr',
        PrayerType.asr: 'Asr',
        PrayerType.maghrib: 'Maghrib',
        PrayerType.isha: 'Isha',
      },
      'tr': {
        PrayerType.fajr: 'Sabah',
        PrayerType.dhuhr: 'Öğle',
        PrayerType.asr: 'İkindi',
        PrayerType.maghrib: 'Akşam',
        PrayerType.isha: 'Yatsı',
      },
      'fr': {
        PrayerType.fajr: 'Fajr',
        PrayerType.dhuhr: 'Dhohr',
        PrayerType.asr: 'Asr',
        PrayerType.maghrib: 'Maghreb',
        PrayerType.isha: 'Icha',
      },
      'es': {
        PrayerType.fajr: 'Fayr',
        PrayerType.dhuhr: 'Dhuhr',
        PrayerType.asr: 'Asr',
        PrayerType.maghrib: 'Magreb',
        PrayerType.isha: 'Isha',
      },
      'ar': {
        PrayerType.fajr: 'الفجر',
        PrayerType.dhuhr: 'الظهر',
        PrayerType.asr: 'العصر',
        PrayerType.maghrib: 'المغرب',
        PrayerType.isha: 'العشاء',
      },
      'ur': {
        PrayerType.fajr: 'فجر',
        PrayerType.dhuhr: 'ظہر',
        PrayerType.asr: 'عصر',
        PrayerType.maghrib: 'مغرب',
        PrayerType.isha: 'عشاء',
      },
      'ps': {
        PrayerType.fajr: 'سهار',
        PrayerType.dhuhr: 'غرمه',
        PrayerType.asr: 'مازدیګر',
        PrayerType.maghrib: 'ماښام',
        PrayerType.isha: 'ماخوستن',
      },
    };
    return values[languageCode]?[this] ?? values['en']![this]!;
  }
}
