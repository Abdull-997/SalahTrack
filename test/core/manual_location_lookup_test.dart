import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:salah_focus/core/location/manual_location_lookup.dart';

class _Gateway implements ManualGeocodingGateway {
  List<Location> matches = [];
  List<Placemark> places = [];

  @override
  Future<List<Location>> forward(String address) async => matches;

  @override
  Future<List<Placemark>> reverse(double latitude, double longitude) async =>
      places;
}

void main() {
  final Location coordinate = Location(
    latitude: 51.2277,
    longitude: 6.7735,
    timestamp: DateTime.utc(2026),
  );

  test('Unicode, accents and case are normalized for prefix matching', () {
    expect(normalizedLocationText('DÜS'), 'dus');
    expect(
      normalizedLocationText('Düsseldorf')
          .startsWith(normalizedLocationText('düs')),
      isTrue,
    );
    expect(normalizedLocationText('TÜRKİYE'), 'turkiye');
    expect(normalizedLocationText('Du\u0308sseldorf'), 'dusseldorf');
  });

  test('search only returns prefix matches in the selected country', () async {
    final _Gateway gateway = _Gateway()
      ..matches = [coordinate]
      ..places = const [
        Placemark(
          locality: 'Düsseldorf',
          administrativeArea: 'Nordrhein-Westfalen',
          isoCountryCode: 'DE',
          country: 'Deutschland',
        ),
      ];
    final lookup = ManualLocationLookup(gateway);
    final results = await lookup.search(
      query: 'dÜs',
      countryCode: 'DE',
      countryName: 'Deutschland',
      timezoneId: 'Europe/Berlin',
    );
    expect(results.single.location.city, 'Düsseldorf');
    expect(results.single.location.latitude, coordinate.latitude);
    expect(results.single.subtitle, 'Nordrhein-Westfalen, Deutschland');
    expect(
      await lookup.search(
        query: 'Kar',
        countryCode: 'DE',
        countryName: 'Deutschland',
        timezoneId: 'Europe/Berlin',
      ),
      isEmpty,
    );
    expect(
      await lookup.search(
        query: 'Düs',
        countryCode: 'PK',
        countryName: 'Pakistan',
        timezoneId: 'Europe/Berlin',
      ),
      isEmpty,
    );
  });

  test('nearby fallback requires reverse-geocoded address evidence', () async {
    final _Gateway gateway = _Gateway()
      ..matches = [coordinate]
      ..places = const [
        Placemark(
          name: 'Kaarst',
          locality: 'Neuss',
          isoCountryCode: 'DE',
          country: 'Deutschland',
        ),
      ];
    final lookup = ManualLocationLookup(gateway);
    final result = await lookup.nearby(
      query: 'Kaarst',
      countryCode: 'DE',
      countryName: 'Deutschland',
      timezoneId: 'Europe/Berlin',
    );
    expect(result?.location.city, 'Neuss');
    expect(result?.location.latitude, coordinate.latitude);

    final unknown = await lookup.nearby(
      query: 'MadeUpPlace',
      countryCode: 'DE',
      countryName: 'Deutschland',
      timezoneId: 'Europe/Berlin',
    );
    expect(unknown, isNull);
  });
}
