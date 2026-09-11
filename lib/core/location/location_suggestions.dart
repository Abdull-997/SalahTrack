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

List<LocationSuggestion> locationSuggestionsFor(String languageCode) =>
    switch (languageCode) {
      'tr' => const [
        LocationSuggestion('Berlin', 'Almanya'),
        LocationSuggestion('Hamburg', 'Almanya'),
        LocationSuggestion('Viyana', 'Avusturya'),
        LocationSuggestion('Zürih', 'İsviçre'),
        LocationSuggestion('Londra', 'Birleşik Krallık'),
        LocationSuggestion('İstanbul', 'Türkiye'),
        LocationSuggestion('Karaçi', 'Pakistan'),
        LocationSuggestion('Kabil', 'Afganistan'),
        LocationSuggestion('Mekke', 'Suudi Arabistan'),
        LocationSuggestion('Medine', 'Suudi Arabistan'),
      ],
      'fr' => const [
        LocationSuggestion('Berlin', 'Allemagne'),
        LocationSuggestion('Hambourg', 'Allemagne'),
        LocationSuggestion('Vienne', 'Autriche'),
        LocationSuggestion('Zurich', 'Suisse'),
        LocationSuggestion('Londres', 'Royaume-Uni'),
        LocationSuggestion('Istanbul', 'Turquie'),
        LocationSuggestion('Karachi', 'Pakistan'),
        LocationSuggestion('Kaboul', 'Afghanistan'),
        LocationSuggestion('La Mecque', 'Arabie saoudite'),
        LocationSuggestion('Médine', 'Arabie saoudite'),
      ],
      'es' => const [
        LocationSuggestion('Berlín', 'Alemania'),
        LocationSuggestion('Hamburgo', 'Alemania'),
        LocationSuggestion('Viena', 'Austria'),
        LocationSuggestion('Zúrich', 'Suiza'),
        LocationSuggestion('Londres', 'Reino Unido'),
        LocationSuggestion('Estambul', 'Turquía'),
        LocationSuggestion('Karachi', 'Pakistán'),
        LocationSuggestion('Kabul', 'Afganistán'),
        LocationSuggestion('La Meca', 'Arabia Saudí'),
        LocationSuggestion('Medina', 'Arabia Saudí'),
      ],
      _ => locationSuggestions,
    };
