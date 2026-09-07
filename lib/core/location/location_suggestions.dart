class LocationSuggestion {
  const LocationSuggestion(this.city, this.country);

  final String city;
  final String country;

  String get label => '$city, $country';
}

/// Frequently used places offered as a quick alternative to GPS or typing.
const List<LocationSuggestion> locationSuggestions = <LocationSuggestion>[
  LocationSuggestion('Berlin', 'Germany'),
  LocationSuggestion('Hamburg', 'Germany'),
  LocationSuggestion('Vienna', 'Austria'),
  LocationSuggestion('Zurich', 'Switzerland'),
  LocationSuggestion('London', 'United Kingdom'),
  LocationSuggestion('Istanbul', 'Türkiye'),
  LocationSuggestion('Karachi', 'Pakistan'),
  LocationSuggestion('Kabul', 'Afghanistan'),
  LocationSuggestion('Makkah', 'Saudi Arabia'),
  LocationSuggestion('Madinah', 'Saudi Arabia'),
];
