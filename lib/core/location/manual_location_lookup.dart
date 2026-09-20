import 'package:geocoding/geocoding.dart';
import 'package:salah_focus/core/location/geocoding_locale.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';

class ManualLocationCandidate {
  const ManualLocationCandidate({
    required this.location,
    required this.region,
    required this.countryCode,
  });

  final UserLocation location;
  final String region;
  final String countryCode;

  String get subtitle =>
      <String>[if (region.isNotEmpty) region, location.country].join(', ');
}

abstract interface class ManualGeocodingGateway {
  Future<List<Location>> forward(String address);
  Future<List<Placemark>> reverse(double latitude, double longitude);
}

class PlatformManualGeocodingGateway implements ManualGeocodingGateway {
  @override
  Future<List<Location>> forward(String address) =>
      locationFromAddress(address);

  @override
  Future<List<Placemark>> reverse(double latitude, double longitude) =>
      placemarkFromCoordinates(latitude, longitude);
}

class ManualLocationLookup {
  ManualLocationLookup([ManualGeocodingGateway? gateway])
    : _gateway = gateway ?? PlatformManualGeocodingGateway();

  final ManualGeocodingGateway _gateway;

  Future<List<ManualLocationCandidate>> search({
    required String query,
    required String countryCode,
    required String countryName,
    required String timezoneId,
    String languageCode = 'en',
  }) async {
    final String text = query.trim();
    if (text.isEmpty) return <ManualLocationCandidate>[];
    if (_gateway is PlatformManualGeocodingGateway) {
      await setLocaleIdentifier(geocodingLocaleIdentifier(languageCode));
    }
    final List<Location> matches = await _gateway
        .forward('$text, $countryName')
        .timeout(const Duration(seconds: 10));
    final List<ManualLocationCandidate> result = <ManualLocationCandidate>[];
    for (final Location match in matches.take(8)) {
      if (!_validCoordinates(match.latitude, match.longitude)) continue;
      final List<Placemark> places = await _gateway
          .reverse(match.latitude, match.longitude)
          .timeout(const Duration(seconds: 10));
      if (places.isEmpty) continue;
      final Placemark place = places.first;
      if (place.isoCountryCode?.toUpperCase() != countryCode.toUpperCase()) {
        continue;
      }
      final ManualLocationCandidate candidate = _candidate(
        match,
        place,
        countryName,
        timezoneId,
        text,
      );
      if (candidate.location.city.isEmpty ||
          !normalizedLocationText(candidate.location.city)
              .startsWith(normalizedLocationText(text))) {
        continue;
      }
      if (result.any(
        (item) =>
            item.location.city == candidate.location.city &&
            item.region == candidate.region,
      )) {
        continue;
      }
      result.add(candidate);
    }
    return result;
  }

  /// Returns a coordinate-backed nearby locality only when the native provider
  /// resolves the entered address inside the selected country.
  Future<ManualLocationCandidate?> nearby({
    required String query,
    required String countryCode,
    required String countryName,
    required String timezoneId,
    String languageCode = 'en',
  }) async {
    final String text = query.trim();
    if (text.isEmpty) return null;
    if (_gateway is PlatformManualGeocodingGateway) {
      await setLocaleIdentifier(geocodingLocaleIdentifier(languageCode));
    }
    final List<Location> matches = await _gateway
        .forward('$text, $countryName')
        .timeout(const Duration(seconds: 10));
    for (final Location match in matches.take(4)) {
      if (!_validCoordinates(match.latitude, match.longitude)) continue;
      final List<Placemark> places = await _gateway
          .reverse(match.latitude, match.longitude)
          .timeout(const Duration(seconds: 10));
      if (places.isEmpty) continue;
      final Placemark place = places.first;
      if (place.isoCountryCode?.toUpperCase() != countryCode.toUpperCase() ||
          (place.locality ?? '').trim().isEmpty) {
        continue;
      }
      // A provider may silently fall back to a country centroid for an
      // unknown address. Require the reverse result to contain evidence of
      // the entered place before offering a nearby city.
      final String normalizedQuery = normalizedLocationText(text);
      final bool addressMatches =
          <String?>[
            place.name,
            place.subLocality,
            place.locality,
            place.street,
            place.thoroughfare,
          ].whereType<String>().any(
            (part) => normalizedLocationText(part).contains(normalizedQuery),
          );
      if (!addressMatches) continue;
      return _candidate(match, place, countryName, timezoneId, text);
    }
    return null;
  }

  ManualLocationCandidate _candidate(
    Location match,
    Placemark place,
    String countryName,
    String timezoneId,
    String query,
  ) {
    final String locality = (place.locality ?? '').trim();
    final String subLocality = (place.subLocality ?? '').trim();
    final String city =
        normalizedLocationText(locality)
            .startsWith(normalizedLocationText(query))
        ? locality
        : normalizedLocationText(subLocality)
              .startsWith(normalizedLocationText(query))
        ? subLocality
        : locality.isNotEmpty
        ? locality
        : subLocality;
    return ManualLocationCandidate(
      location: UserLocation(
        latitude: match.latitude,
        longitude: match.longitude,
        city: city,
        country: (place.country ?? countryName).trim(),
        timezoneId: timezoneId,
        isAutomatic: false,
      ),
      region: (place.administrativeArea ?? '').trim(),
      countryCode: (place.isoCountryCode ?? '').toUpperCase(),
    );
  }

  bool _validCoordinates(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

String normalizedLocationText(String value) {
  const Map<String, String> replacements = <String, String>{
    'ä': 'a',
    'ö': 'o',
    'ü': 'u',
    'ß': 'ss',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ç': 'c',
    'ñ': 'n',
    'ş': 's',
    'ğ': 'g',
    'ı': 'i',
    'İ': 'i',
    'ی': 'ي',
    'ى': 'ي',
    'ک': 'ك',
    'ۀ': 'ه',
    'ة': 'ه',
  };
  final String lower = value.toLowerCase();
  return lower.runes
      .map(
        (rune) =>
            replacements[String.fromCharCode(rune)] ??
            String.fromCharCode(rune),
      )
      .join()
      .replaceAll(RegExp(r'[\u0300-\u036F\u064B-\u065F]'), '');
}
