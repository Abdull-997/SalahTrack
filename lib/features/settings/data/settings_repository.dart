import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/app/localization/app_language.dart';
import 'package:salah_focus/features/ramadan/domain/ramadan_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  const AppPreferences({
    required this.prayerSettings,
    required this.localeCode,
    required this.themeMode,
    required this.onboardingComplete,
    this.location,
    this.ramadanSettings = const RamadanSettings(),
    this.firstLaunchAtUtc,
    this.reviewRequestAttempted = false,
  });

  final PrayerSettings prayerSettings;
  final UserLocation? location;
  final String localeCode;
  final String themeMode;
  final bool onboardingComplete;
  final RamadanSettings ramadanSettings;
  final DateTime? firstLaunchAtUtc;
  final bool reviewRequestAttempted;

  AppPreferences copyWith({
    PrayerSettings? prayerSettings,
    UserLocation? location,
    bool clearLocation = false,
    String? localeCode,
    String? themeMode,
    bool? onboardingComplete,
    RamadanSettings? ramadanSettings,
    DateTime? firstLaunchAtUtc,
    bool? reviewRequestAttempted,
  }) {
    return AppPreferences(
      prayerSettings: prayerSettings ?? this.prayerSettings,
      location: clearLocation ? null : location ?? this.location,
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      ramadanSettings: ramadanSettings ?? this.ramadanSettings,
      firstLaunchAtUtc: firstLaunchAtUtc ?? this.firstLaunchAtUtc,
      reviewRequestAttempted:
          reviewRequestAttempted ?? this.reviewRequestAttempted,
    );
  }
}

class SettingsRepository {
  static const String _prayerSettingsKey = 'prayer_settings_v1';
  static const String _locationKey = 'user_location_v1';
  static const String _localeKey = 'locale_code';
  static const String _themeKey = 'theme_mode';
  static const String _onboardingKey = 'onboarding_complete';
  static const String _ramadanSettingsKey = 'ramadan_settings_v1';
  static const String _firstLaunchKey = 'first_successful_launch_utc';
  static const String _reviewAttemptedKey = 'review_request_attempted_v1';

  AppPreferences defaults() {
    final String localeCode = _systemLocaleCode();
    return AppPreferences(
      prayerSettings: PrayerSettings(
        confirmationText: PrayerSettings.defaultConfirmationText(localeCode),
      ),
      localeCode: localeCode,
      themeMode: 'system',
      onboardingComplete: false,
      firstLaunchAtUtc: DateTime.now().toUtc(),
    );
  }

  Future<AppPreferences> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    PrayerSettings prayerSettings = const PrayerSettings();
    final String? settingsJson = prefs.getString(_prayerSettingsKey);
    if (settingsJson != null) {
      try {
        final Object? decoded = jsonDecode(settingsJson);
        if (decoded is Map) {
          prayerSettings = PrayerSettings.fromJson(
            Map<String, Object?>.from(decoded),
          );
        }
      } on Object {
        // Stored preferences must never prevent the app from starting after an
        // update or a partially corrupted write.
        prayerSettings = const PrayerSettings();
      }
    }

    UserLocation? location;
    final String? locationJson = prefs.getString(_locationKey);
    if (locationJson != null) {
      try {
        final Object? decoded = jsonDecode(locationJson);
        if (decoded is Map) {
          location = UserLocation.fromJson(Map<String, Object?>.from(decoded));
        }
      } on Object {
        location = null;
      }
    }

    final String? savedLocale = prefs.getString(_localeKey);
    final String storedLocale = savedLocale ?? _systemLocaleCode();
    final String localeCode =
        appLanguages.any(
          (AppLanguage language) => language.code == storedLocale,
        )
        ? storedLocale
        : 'de';
    if (prayerSettings.usesDefaultConfirmationText) {
      prayerSettings = prayerSettings.copyWith(
        confirmationText: PrayerSettings.defaultConfirmationText(localeCode),
      );
    }
    final String storedTheme = prefs.getString(_themeKey) ?? 'system';
    RamadanSettings ramadanSettings = const RamadanSettings();
    final String? ramadanJson = prefs.getString(_ramadanSettingsKey);
    if (ramadanJson != null) {
      try {
        final Object? decoded = jsonDecode(ramadanJson);
        if (decoded is Map) {
          ramadanSettings = RamadanSettings.fromJson(
            Map<String, Object?>.from(decoded),
          );
        }
      } on Object {
        ramadanSettings = const RamadanSettings();
      }
    }

    DateTime? firstLaunchAtUtc = DateTime.tryParse(
      prefs.getString(_firstLaunchKey) ?? '',
    )?.toUtc();
    if (firstLaunchAtUtc == null) {
      firstLaunchAtUtc = DateTime.now().toUtc();
      await prefs.setString(
        _firstLaunchKey,
        firstLaunchAtUtc.toIso8601String(),
      );
    }
    return AppPreferences(
      prayerSettings: prayerSettings,
      location: location,
      localeCode: localeCode,
      themeMode: <String>{'system', 'light', 'dark'}.contains(storedTheme)
          ? storedTheme
          : 'system',
      onboardingComplete: prefs.getBool(_onboardingKey) ?? false,
      ramadanSettings: ramadanSettings,
      firstLaunchAtUtc: firstLaunchAtUtc,
      reviewRequestAttempted: prefs.getBool(_reviewAttemptedKey) ?? false,
    );
  }

  Future<void> savePrayerSettings(PrayerSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prayerSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> saveLocation(UserLocation location) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationKey, jsonEncode(location.toJson()));
  }

  Future<void> saveLocale(String localeCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, localeCode);
  }

  Future<void> saveThemeMode(String mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
  }

  Future<void> markOnboardingComplete() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<void> saveRamadanSettings(RamadanSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ramadanSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> markReviewRequestAttempted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewAttemptedKey, true);
  }

  String _systemLocaleCode() {
    final String languageCode = PlatformDispatcher.instance.locale.languageCode;
    return appLanguages
            .map((AppLanguage language) => language.code)
            .contains(languageCode)
        ? languageCode
        : 'en';
  }
}
