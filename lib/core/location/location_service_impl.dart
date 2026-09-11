import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salah_focus/core/errors/app_exception.dart';
import 'package:salah_focus/core/location/location_service.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';

class LocationServiceImpl implements LocationService {
  @override
  Stream<UserLocation> automaticLocationUpdates({
    required String deviceTimezoneId,
    required String languageCode,
  }) =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1000,
        ),
      ).asyncMap((Position position) async {
        String city = '';
        String country = '';
        try {
          await setLocaleIdentifier(_localeIdentifier(languageCode));
          final List<Placemark> places = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (places.isNotEmpty) {
            final Placemark place = places.first;
            city =
                place.locality ??
                place.subAdministrativeArea ??
                place.administrativeArea ??
                '';
            country = place.country ?? '';
          }
        } on Object {
          // Keep coordinates even when reverse geocoding is unavailable.
        }
        return UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          city: city,
          country: country,
          timezoneId: deviceTimezoneId,
          isAutomatic: true,
        );
      });
  @override
  Future<UserLocation> currentLocation({
    required String deviceTimezoneId,
    required String languageCode,
  }) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationException(
          'Standortdienste sind deaktiviert. Du kannst stattdessen eine Stadt auswählen.',
        );
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const LocationException(
          'Standortzugriff wurde nicht erlaubt. Du kannst eine Stadt manuell auswählen.',
        );
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      String city = '';
      String country = '';
      try {
        await setLocaleIdentifier(_localeIdentifier(languageCode));
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          city =
              placemarks.first.locality ??
              placemarks.first.subAdministrativeArea ??
              '';
          country = placemarks.first.country ?? '';
        }
      } on Object {
        // Fallback: Koordinaten beibehalten
      }

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
        timezoneId: deviceTimezoneId,
        isAutomatic: true,
      );
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw LocationException('Standort konnte nicht ermittelt werden: $error');
    }
  }

  @override
  Future<UserLocation> geocodeManual({
    required String city,
    required String country,
    required String deviceTimezoneId,
    required String languageCode,
  }) async {
    final String cleanedCity = city.trim();
    final String cleanedCountry = country.trim();
    if (cleanedCity.isEmpty || cleanedCountry.isEmpty) {
      throw const LocationException('Bitte Stadt und Land angeben.');
    }
    try {
      await setLocaleIdentifier(_localeIdentifier(languageCode));
      final List<Location> matches = await locationFromAddress(
        '$cleanedCity, $cleanedCountry',
      );
      if (matches.isEmpty) {
        throw const LocationException('Dieser Ort wurde nicht gefunden.');
      }
      final Location first = matches.first;
      return UserLocation(
        latitude: first.latitude,
        longitude: first.longitude,
        city: cleanedCity,
        country: cleanedCountry,
        timezoneId: deviceTimezoneId,
        isAutomatic: false,
      );
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw LocationException('Ort konnte nicht aufgelöst werden: $error');
    }
  }

  @override
  Future<UserLocation> localizeLocation(
    UserLocation location, {
    required String languageCode,
  }) async {
    try {
      await setLocaleIdentifier(_localeIdentifier(languageCode));
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isEmpty) return location;
      final Placemark place = placemarks.first;
      return UserLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        city: place.locality ?? place.subAdministrativeArea ?? location.city,
        country: place.country ?? location.country,
        timezoneId: location.timezoneId,
        isAutomatic: location.isAutomatic,
      );
    } on Object {
      return location;
    }
  }

  String _localeIdentifier(String languageCode) => switch (languageCode) {
    'ar' => 'ar_SA',
    'bn' => 'bn_BD',
    'ur' => 'ur_PK',
    'ps' => 'ps_AF',
    'de' => 'de_DE',
    'fa' => 'fa_IR',
    'fr' => 'fr_FR',
    'es' => 'es_ES',
    'ha' => 'ha_NG',
    'id' => 'id_ID',
    'jv' => 'jv_ID',
    'ms' => 'ms_MY',
    'nl' => 'nl_NL',
    'ru' => 'ru_RU',
    'so' => 'so_SO',
    'sw' => 'sw_TZ',
    'ce' => 'ce_RU',
    'tr' => 'tr_TR',
    _ => 'en_US',
  };
}
