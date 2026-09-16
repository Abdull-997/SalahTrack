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
      'id' => const [
        LocationSuggestion('Berlin', 'Jerman'),
        LocationSuggestion('Hamburg', 'Jerman'),
        LocationSuggestion('Wina', 'Austria'),
        LocationSuggestion('Zürich', 'Swiss'),
        LocationSuggestion('London', 'Britania Raya'),
        LocationSuggestion('Istanbul', 'Turki'),
        LocationSuggestion('Karachi', 'Pakistan'),
        LocationSuggestion('Kabul', 'Afganistan'),
        LocationSuggestion('Makkah', 'Arab Saudi'),
        LocationSuggestion('Madinah', 'Arab Saudi'),
      ],
      'bn' => const [
        LocationSuggestion('বার্লিন', 'জার্মানি'),
        LocationSuggestion('হামবুর্গ', 'জার্মানি'),
        LocationSuggestion('ভিয়েনা', 'অস্ট্রিয়া'),
        LocationSuggestion('জুরিখ', 'সুইজারল্যান্ড'),
        LocationSuggestion('লন্ডন', 'যুক্তরাজ্য'),
        LocationSuggestion('ইস্তাম্বুল', 'তুরস্ক'),
        LocationSuggestion('করাচি', 'পাকিস্তান'),
        LocationSuggestion('কাবুল', 'আফগানিস্তান'),
        LocationSuggestion('মক্কা', 'সৌদি আরব'),
        LocationSuggestion('মদিনা', 'সৌদি আরব'),
      ],
      'pa' => const [
        LocationSuggestion('برلن', 'جرمنی'),
        LocationSuggestion('ہیمبرگ', 'جرمنی'),
        LocationSuggestion('ویانا', 'آسٹریا'),
        LocationSuggestion('زیورخ', 'سوئٹزرلینڈ'),
        LocationSuggestion('لندن', 'برطانیہ'),
        LocationSuggestion('استنبول', 'ترکی'),
        LocationSuggestion('کراچی', 'پاکستان'),
        LocationSuggestion('کابل', 'افغانستان'),
        LocationSuggestion('مکہ', 'سعودی عرب'),
        LocationSuggestion('مدینہ', 'سعودی عرب'),
      ],
      'fa' => const [
        LocationSuggestion('برلین', 'آلمان'),
        LocationSuggestion('هامبورگ', 'آلمان'),
        LocationSuggestion('وین', 'اتریش'),
        LocationSuggestion('زوریخ', 'سوئیس'),
        LocationSuggestion('لندن', 'بریتانیا'),
        LocationSuggestion('استانبول', 'ترکیه'),
        LocationSuggestion('کراچی', 'پاکستان'),
        LocationSuggestion('کابل', 'افغانستان'),
        LocationSuggestion('مکه', 'عربستان سعودی'),
        LocationSuggestion('مدینه', 'عربستان سعودی'),
      ],
      'ms' => const [
        LocationSuggestion('Berlin', 'Jerman'),
        LocationSuggestion('Hamburg', 'Jerman'),
        LocationSuggestion('Vienna', 'Austria'),
        LocationSuggestion('Zurich', 'Switzerland'),
        LocationSuggestion('London', 'United Kingdom'),
        LocationSuggestion('Istanbul', 'Turkiye'),
        LocationSuggestion('Karachi', 'Pakistan'),
        LocationSuggestion('Kabul', 'Afghanistan'),
        LocationSuggestion('Makkah', 'Arab Saudi'),
        LocationSuggestion('Madinah', 'Arab Saudi'),
      ],
      _ => locationSuggestions,
    };
