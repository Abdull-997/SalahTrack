import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:salah_focus/core/location/manual_location_lookup.dart';

class _GeocodingGateway implements ManualGeocodingGateway {
  List<Location> matches = <Location>[];
  List<Placemark> places = <Placemark>[];

  @override
  Future<List<Location>> forward(String address) async => matches;

  @override
  Future<List<Placemark>> reverse(double latitude, double longitude) async =>
      places;
}

class _PhotonClient implements PhotonSearchClient {
  Object? response;
  Map<String, Object?>? lastParameters;

  @override
  Future<Object?> search(Map<String, Object?> parameters) async {
    lastParameters = parameters;
    return response;
  }
}

Map<String, Object?> _feature({
  required String name,
  required String countryCode,
  required double latitude,
  required double longitude,
  String type = 'city',
  String? city,
  String? state,
  String? country,
}) => <String, Object?>{
  'geometry': <String, Object?>{
    'coordinates': <Object?>[longitude, latitude],
  },
  'properties': <String, Object?>{
    'name': name,
    'countrycode': countryCode,
    'type': type,
    'city': ?city,
    'state': ?state,
    'country': ?country,
  },
};

void main() {
  final Location coordinate = Location(
    latitude: 51.2277,
    longitude: 6.7735,
    timestamp: DateTime.utc(2026),
  );

  test('Unicode, accents and case are normalized for matching', () {
    expect(normalizedLocationText('DÜS'), 'dus');
    expect(
      normalizedLocationText('Düsseldorf')
          .startsWith(normalizedLocationText('düs')),
      isTrue,
    );
    expect(normalizedLocationText('TÜRKİYE'), 'turkiye');
    expect(normalizedLocationText('Du\u0308sseldorf'), 'dusseldorf');
  });

  test(
    'Photon search sends country, language, and place-layer filters',
    () async {
      final _PhotonClient client = _PhotonClient()
        ..response = <String, Object?>{
          'features': <Object?>[
            _feature(
              name: 'Düsseldorf',
              countryCode: 'DE',
              latitude: 51.2277,
              longitude: 6.7735,
              state: 'Nordrhein-Westfalen',
              country: 'Deutschland',
            ),
            _feature(
              name: 'Gerresheim',
              countryCode: 'DE',
              latitude: 51.2375,
              longitude: 6.8625,
              type: 'district',
              city: 'Düsseldorf',
              state: 'Nordrhein-Westfalen',
              country: 'Deutschland',
            ),
          ],
        };
      final PhotonPlaceSearchGateway gateway = PhotonPlaceSearchGateway(
        client: client,
      );

      final List<ManualLocationCandidate> results = await gateway.search(
        query: 'Düs',
        countryCode: 'de',
        countryName: 'Deutschland',
        timezoneId: 'Europe/Berlin',
        languageCode: 'de',
      );

      expect(client.lastParameters?['q'], 'Düs');
      expect(client.lastParameters?['countrycode'], 'DE');
      expect(client.lastParameters?['lang'], 'de');
      expect(client.lastParameters?['layer'], <String>[
        'city',
        'district',
        'locality',
      ]);
      expect(results.map((item) => item.location.city), <String>[
        'Düsseldorf',
        'Düsseldorf-Gerresheim',
      ]);
      expect(results.first.location.latitude, 51.2277);
      expect(results.first.location.longitude, 6.7735);
      expect(results.first.subtitle, 'Nordrhein-Westfalen, Deutschland');
    },
  );

  test('response is defensively restricted to the selected country', () async {
    final _PhotonClient client = _PhotonClient()
      ..response = <String, Object?>{
        'features': <Object?>[
          _feature(
            name: 'Hasaka',
            countryCode: 'SY',
            latitude: 36.5024,
            longitude: 40.7477,
            state: 'Al-Hasakah',
            country: 'Syria',
          ),
          _feature(
            name: 'Haslach',
            countryCode: 'DE',
            latitude: 48.276,
            longitude: 8.087,
            country: 'Germany',
          ),
        ],
      };
    final PhotonPlaceSearchGateway gateway = PhotonPlaceSearchGateway(
      client: client,
    );

    final List<ManualLocationCandidate> results = await gateway.search(
      query: 'Has',
      countryCode: 'SY',
      countryName: 'Syria',
      timezoneId: 'Asia/Damascus',
      languageCode: 'en',
    );

    expect(results, hasLength(1));
    expect(results.single.location.city, 'Hasaka');
    expect(results.single.countryCode, 'SY');
    expect(results.single.location.latitude, 36.5024);
    expect(results.single.location.longitude, 40.7477);
  });

  test('malformed and invalid coordinates are ignored', () async {
    final _PhotonClient client = _PhotonClient()
      ..response = <String, Object?>{
        'features': <Object?>[
          _feature(
            name: 'Outside',
            countryCode: 'DE',
            latitude: 100,
            longitude: 6.7,
          ),
          <String, Object?>{'properties': <String, Object?>{}},
        ],
      };
    final PhotonPlaceSearchGateway gateway = PhotonPlaceSearchGateway(
      client: client,
    );

    expect(
      await gateway.search(
        query: 'Out',
        countryCode: 'DE',
        countryName: 'Germany',
        timezoneId: 'Europe/Berlin',
        languageCode: 'en',
      ),
      isEmpty,
    );
  });

  test('nearby fallback requires reverse-geocoded address evidence', () async {
    final _GeocodingGateway gateway = _GeocodingGateway()
      ..matches = <Location>[coordinate]
      ..places = const <Placemark>[
        Placemark(
          name: 'Kaarst',
          locality: 'Neuss',
          isoCountryCode: 'DE',
          country: 'Deutschland',
        ),
      ];
    final ManualLocationLookup lookup = ManualLocationLookup(
      geocodingGateway: gateway,
    );
    final ManualLocationCandidate? result = await lookup.nearby(
      query: 'Kaarst',
      countryCode: 'DE',
      countryName: 'Deutschland',
      timezoneId: 'Europe/Berlin',
    );
    expect(result?.location.city, 'Neuss');
    expect(result?.location.latitude, coordinate.latitude);

    final ManualLocationCandidate? unknown = await lookup.nearby(
      query: 'MadeUpPlace',
      countryCode: 'DE',
      countryName: 'Deutschland',
      timezoneId: 'Europe/Berlin',
    );
    expect(unknown, isNull);
  });
}
