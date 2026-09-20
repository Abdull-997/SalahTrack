import 'package:salah_focus/features/prayer_times/domain/user_location.dart';

abstract interface class LocationService {
  Future<UserLocation> currentLocation({
    required String deviceTimezoneId,
    required String languageCode,
  });

  Stream<UserLocation> automaticLocationUpdates({
    required String deviceTimezoneId,
    required String languageCode,
  });

  Future<UserLocation> geocodeManual({
    required String city,
    required String country,
    required String deviceTimezoneId,
    required String languageCode,
  });

  Future<UserLocation> localizeLocation(
    UserLocation location, {
    required String languageCode,
  });

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}
