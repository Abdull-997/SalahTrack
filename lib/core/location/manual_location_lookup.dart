import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:salah_focus/core/location/geocoding_locale.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';

const String defaultPlaceSearchBaseUrl = String.fromEnvironment(
  'PLACE_SEARCH_BASE_URL',
  defaultValue: 'https://photon.komoot.io',
);

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

abstract interface class ManualPlaceSearchGateway {
  Future<List<ManualLocationCandidate>> search({
    required String query,
    required String countryCode,
    required String countryName,
    required String timezoneId,
    required String languageCode,
  });
}

abstract interface class PhotonSearchClient {
  Future<Object?> search(Map<String, Object?> parameters);
}

class DioPhotonSearchClient implements PhotonSearchClient {
  DioPhotonSearchClient({Dio? dio, String baseUrl = defaultPlaceSearchBaseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 6),
              listFormat: ListFormat.multi,
              headers: const <String, Object?>{
                'Accept': 'application/json',
                'User-Agent': 'SalahTrack/1.0 location-search',
              },
            ),
          );

  final Dio _dio;

  @override
  Future<Object?> search(Map<String, Object?> parameters) async {
    final Response<Object?> response = await _dio.get<Object?>(
      '/api/',
      queryParameters: parameters,
    );
    return response.data;
  }
}

/// Search-as-you-type city lookup backed by Photon/OpenStreetMap.
///
/// Unlike the platform geocoder, Photon returns multiple partial-name matches
/// and applies an ISO country-code restriction before returning results.
class PhotonPlaceSearchGateway implements ManualPlaceSearchGateway {
  PhotonPlaceSearchGateway({PhotonSearchClient? client})
    : _client = client ?? DioPhotonSearchClient();

  final PhotonSearchClient _client;

  @override
  Future<List<ManualLocationCandidate>> search({
    required String query,
    required String countryCode,
    required String countryName,
    required String timezoneId,
    required String languageCode,
  }) async {
    final String text = query.trim();
    if (text.length < 2) return const <ManualLocationCandidate>[];
    final Object? data = await _client.search(<String, Object?>{
      'q': text,
      'countrycode': countryCode.toUpperCase(),
      'limit': 15,
      'lang': languageCode,
      'layer': const <String>['city', 'district', 'locality'],
    });
    if (data is! Map) return const <ManualLocationCandidate>[];
    final Object? rawFeatures = data['features'];
    if (rawFeatures is! List) return const <ManualLocationCandidate>[];

    final String expectedCountry = countryCode.toUpperCase();
    final String normalizedQuery = normalizedLocationText(text);
    final List<ManualLocationCandidate> candidates =
        <ManualLocationCandidate>[];
    for (final Object? rawFeature in rawFeatures) {
      final ManualLocationCandidate? candidate = _parseFeature(
        rawFeature,
        expectedCountry: expectedCountry,
        countryName: countryName,
        timezoneId: timezoneId,
        normalizedQuery: normalizedQuery,
      );
      if (candidate == null) continue;
      final String identity = normalizedLocationText(
        '${candidate.location.city}|${candidate.region}|'
        '${candidate.location.latitude}|${candidate.location.longitude}',
      );
      if (candidates.any(
        (ManualLocationCandidate item) =>
            normalizedLocationText(
              '${item.location.city}|${item.region}|'
              '${item.location.latitude}|${item.location.longitude}',
            ) ==
            identity,
      )) {
        continue;
      }
      candidates.add(candidate);
    }
    return candidates;
  }

  ManualLocationCandidate? _parseFeature(
    Object? rawFeature, {
    required String expectedCountry,
    required String countryName,
    required String timezoneId,
    required String normalizedQuery,
  }) {
    if (rawFeature is! Map) return null;
    final Object? rawProperties = rawFeature['properties'];
    final Object? rawGeometry = rawFeature['geometry'];
    if (rawProperties is! Map || rawGeometry is! Map) return null;
    final Map<String, Object?> properties = Map<String, Object?>.from(
      rawProperties,
    );
    final Map<String, Object?> geometry = Map<String, Object?>.from(
      rawGeometry,
    );
    final String featureCountry = _text(properties['countrycode'])
        .toUpperCase();
    if (featureCountry != expectedCountry) return null;

    final Object? rawCoordinates = geometry['coordinates'];
    if (rawCoordinates is! List || rawCoordinates.length < 2) return null;
    final double? longitude = _coordinate(rawCoordinates[0]);
    final double? latitude = _coordinate(rawCoordinates[1]);
    if (latitude == null ||
        longitude == null ||
        !_validCoordinates(latitude, longitude)) {
      return null;
    }

    final String name = _text(properties['name']);
    final String parentCity = _text(properties['city']);
    if (name.isEmpty) return null;
    final String type = _text(properties['type']);
    final bool nestedPlace =
        type == 'district' || type == 'locality' || type == 'borough';
    final String label =
        nestedPlace &&
            parentCity.isNotEmpty &&
            normalizedLocationText(parentCity) != normalizedLocationText(name)
        ? '$parentCity-$name'
        : name;
    final String searchable = normalizedLocationText(
      '$label $name $parentCity ${_text(properties['district'])}',
    );
    if (!searchable.contains(normalizedQuery)) return null;

    final String region = <String>[
      _text(properties['state']),
      _text(properties['county']),
    ].firstWhere((String value) => value.isNotEmpty, orElse: () => '');
    final String country = _text(properties['country']);
    return ManualLocationCandidate(
      location: UserLocation(
        latitude: latitude,
        longitude: longitude,
        city: label,
        country: country.isEmpty ? countryName : country,
        timezoneId: timezoneId,
        isAutomatic: false,
      ),
      region: region,
      countryCode: featureCountry,
    );
  }

  String _text(Object? value) => value is String ? value.trim() : '';

  double? _coordinate(Object? value) => switch (value) {
    num number => number.toDouble(),
    String text => double.tryParse(text),
    _ => null,
  };
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
  ManualLocationLookup({
    ManualPlaceSearchGateway? placeSearchGateway,
    ManualGeocodingGateway? geocodingGateway,
  }) : _placeSearchGateway = placeSearchGateway ?? PhotonPlaceSearchGateway(),
       _geocodingGateway = geocodingGateway ?? PlatformManualGeocodingGateway();

  final ManualPlaceSearchGateway _placeSearchGateway;
  final ManualGeocodingGateway _geocodingGateway;

  Future<List<ManualLocationCandidate>> search({
    required String query,
    required String countryCode,
    required String countryName,
    required String timezoneId,
    String languageCode = 'en',
  }) => _placeSearchGateway.search(
    query: query,
    countryCode: countryCode,
    countryName: countryName,
    timezoneId: timezoneId,
    languageCode: languageCode,
  );

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
    if (_geocodingGateway is PlatformManualGeocodingGateway) {
      await setLocaleIdentifier(geocodingLocaleIdentifier(languageCode));
    }
    final List<Location> matches = await _geocodingGateway
        .forward('$text, $countryName')
        .timeout(const Duration(seconds: 10));
    for (final Location match in matches.take(4)) {
      if (!_validCoordinates(match.latitude, match.longitude)) continue;
      final List<Placemark> places = await _geocodingGateway
          .reverse(match.latitude, match.longitude)
          .timeout(const Duration(seconds: 10));
      if (places.isEmpty) continue;
      final Placemark place = places.first;
      if (place.isoCountryCode?.toUpperCase() != countryCode.toUpperCase() ||
          (place.locality ?? '').trim().isEmpty) {
        continue;
      }
      final String normalizedQuery = normalizedLocationText(text);
      final bool addressMatches =
          <String?>[
            place.name,
            place.subLocality,
            place.locality,
            place.street,
            place.thoroughfare,
          ].whereType<String>().any(
            (String part) =>
                normalizedLocationText(part).contains(normalizedQuery),
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
}

bool _validCoordinates(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

String normalizedLocationText(String value) {
  const Map<String, String> replacements = <String, String>{
    'ä': 'a',
    'ö': 'o',
    'ü': 'u',
    'ß': 'ss',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
    'æ': 'ae',
    'ç': 'c',
    'č': 'c',
    'ć': 'c',
    'ď': 'd',
    'đ': 'd',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'ě': 'e',
    'ğ': 'g',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ı': 'i',
    'ľ': 'l',
    'ł': 'l',
    'ñ': 'n',
    'ń': 'n',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ø': 'o',
    'ř': 'r',
    'š': 's',
    'ş': 's',
    'ť': 't',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ž': 'z',
  };
  String normalized = value.toLowerCase();
  for (final MapEntry<String, String> replacement in replacements.entries) {
    normalized = normalized.replaceAll(replacement.key, replacement.value);
  }
  return normalized
      .replaceAll(RegExp(r'[\u0300-\u036F\u064B-\u065F]'), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();
}
