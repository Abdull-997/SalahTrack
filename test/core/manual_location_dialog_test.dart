import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/app/localization/manual_location_translations.dart';
import 'package:salah_focus/core/location/country_names.dart';
import 'package:salah_focus/core/location/manual_location_dialog.dart';
import 'package:salah_focus/core/location/manual_location_lookup.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';

class _Lookup extends ManualLocationLookup {
  final List<ManualLocationCandidate> results = <ManualLocationCandidate>[];
  Completer<List<ManualLocationCandidate>>? pending;
  final Map<String, Completer<List<ManualLocationCandidate>>> delayed =
      <String, Completer<List<ManualLocationCandidate>>>{};
  Object? searchError;
  String? lastQuery;
  String? lastCountry;
  int searchCount = 0;

  @override
  Future<List<ManualLocationCandidate>> search({
    required String query,
    required String countryCode,
    required String countryName,
    required String timezoneId,
    String languageCode = 'en',
  }) {
    searchCount++;
    lastQuery = query;
    lastCountry = countryCode;
    if (searchError != null) {
      return Future<List<ManualLocationCandidate>>.error(searchError!);
    }
    return delayed[query]?.future ?? pending?.future ?? Future.value(results);
  }
}

const ManualLocationCandidate duesseldorf = ManualLocationCandidate(
  location: UserLocation(
    latitude: 51.2277,
    longitude: 6.7735,
    city: 'Düsseldorf',
    country: 'Deutschland',
    timezoneId: 'Europe/Berlin',
    isAutomatic: false,
  ),
  region: 'Nordrhein-Westfalen',
  countryCode: 'DE',
);

const ManualLocationCandidate hasaka = ManualLocationCandidate(
  location: UserLocation(
    latitude: 36.5024,
    longitude: 40.7477,
    city: 'Hasaka',
    country: 'Syrien',
    timezoneId: 'Europe/Berlin',
    isAutomatic: false,
  ),
  region: 'Al-Hasakah',
  countryCode: 'SY',
);

Widget _app(
  _Lookup lookup, {
  Locale locale = const Locale('de'),
  ValueChanged<UserLocation?>? onResult,
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppStrings.supportedLocales,
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppStrings.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: Builder(
      builder: (BuildContext context) => Center(
        child: FilledButton(
          onPressed: () async {
            final UserLocation? result = await showDialog<UserLocation>(
              context: context,
              builder: (_) => ManualLocationDialog(
                timezoneId: 'Europe/Berlin',
                lookup: lookup,
              ),
            );
            onResult?.call(result);
          },
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _selectCountry(
  WidgetTester tester, {
  required String query,
  required String label,
}) async {
  await tester.tap(find.byKey(const Key('manual-country-dropdown')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('country-search-field')), query);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _selectGermany(WidgetTester tester) =>
    _selectCountry(tester, query: 'Deu', label: 'Deutschland');

Future<void> _openCitySearch(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('manual-city-dropdown')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('manual-city-search-field')), findsOneWidget);
}

FilledButton _saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Speichern'));

OutlinedButton _cityDropdownButton(WidgetTester tester) =>
    tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const Key('manual-city-dropdown')),
        matching: find.byType(OutlinedButton),
      ),
    );

void main() {
  test('all supported locales have manual location text and country names', () {
    for (final Locale locale in AppStrings.supportedLocales) {
      final String code = locale.languageCode;
      expect(
        manualLocationTranslations[code]?.keys,
        containsAll(manualLocationTranslations['en']!.keys),
      );
      expect(countryNames[code]?['DE'], isNotEmpty);
      expect(countryNames[code]?['PK'], isNotEmpty);
      expect(countryNames[code]?['TR'], isNotEmpty);
    }
  });

  testWidgets('country selection enables a real city dropdown', (tester) async {
    await tester.pumpWidget(_app(_Lookup()));
    await _openDialog(tester);

    expect(_cityDropdownButton(tester).onPressed, isNull);
    expect(find.textContaining('Standortbestimmung'), findsOneWidget);

    await _selectGermany(tester);

    expect(_cityDropdownButton(tester).onPressed, isNotNull);
    await _openCitySearch(tester);
  });

  testWidgets('city autocomplete is debounced and stores coordinates', (
    tester,
  ) async {
    final _Lookup lookup = _Lookup()..results.add(duesseldorf);
    UserLocation? saved;
    await tester.pumpWidget(_app(lookup, onResult: (value) => saved = value));
    await _openDialog(tester);
    await _selectGermany(tester);
    expect(_saveButton(tester).onPressed, isNull);
    await _openCitySearch(tester);

    await tester.enterText(
      find.byKey(const Key('manual-city-search-field')),
      'Düs',
    );
    await tester.pump(const Duration(milliseconds: 399));
    expect(lookup.searchCount, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(lookup.lastQuery, 'Düs');
    expect(lookup.lastCountry, 'DE');
    expect(find.text('Düsseldorf'), findsOneWidget);
    expect(find.text('Nordrhein-Westfalen, Deutschland'), findsOneWidget);
    await tester.tap(find.text('Düsseldorf'));
    await tester.pumpAndSettle();
    expect(_saveButton(tester).onPressed, isNotNull);
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(saved?.latitude, 51.2277);
    expect(saved?.longitude, 6.7735);
    expect(saved?.city, 'Düsseldorf');
  });

  testWidgets('city search is filtered by the selected country', (
    tester,
  ) async {
    final _Lookup lookup = _Lookup()..results.add(hasaka);
    await tester.pumpWidget(_app(lookup));
    await _openDialog(tester);
    await _selectCountry(tester, query: 'Syr', label: 'Syrien');
    await _openCitySearch(tester);

    await tester.enterText(
      find.byKey(const Key('manual-city-search-field')),
      'Has',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(lookup.lastCountry, 'SY');
    expect(find.text('Hasaka'), findsOneWidget);
  });

  testWidgets('editing a selected city invalidates the saved coordinates', (
    tester,
  ) async {
    final _Lookup lookup = _Lookup()..results.add(duesseldorf);
    await tester.pumpWidget(_app(lookup));
    await _openDialog(tester);
    await _selectGermany(tester);
    await _openCitySearch(tester);
    await tester.enterText(
      find.byKey(const Key('manual-city-search-field')),
      'Düs',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.text('Düsseldorf'));
    await tester.pumpAndSettle();
    expect(_saveButton(tester).onPressed, isNotNull);

    await _openCitySearch(tester);
    await tester.enterText(
      find.byKey(const Key('manual-city-search-field')),
      'Düsseldorf Altstadt',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('manual-city-cancel')));
    await tester.pumpAndSettle();

    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('loading and no-results states only appear after a search', (
    tester,
  ) async {
    final Completer<List<ManualLocationCandidate>> pending =
        Completer<List<ManualLocationCandidate>>();
    final _Lookup lookup = _Lookup()..pending = pending;
    await tester.pumpWidget(_app(lookup));
    await _openDialog(tester);
    await _selectGermany(tester);
    await _openCitySearch(tester);

    expect(find.text('Keine passenden Orte gefunden.'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('manual-city-search-field')),
      'D',
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Keine passenden Orte gefunden.'), findsNothing);
    expect(lookup.searchCount, 0);

    await tester.enterText(
      find.byKey(const Key('manual-city-search-field')),
      'Unknown',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Suche läuft…'), findsOneWidget);
    pending.complete(<ManualLocationCandidate>[]);
    await tester.pumpAndSettle();

    expect(find.text('Keine passenden Orte gefunden.'), findsOneWidget);
  });

  testWidgets('older search results never replace newer results', (
    tester,
  ) async {
    final _Lookup lookup = _Lookup()
      ..delayed['Dü'] = Completer<List<ManualLocationCandidate>>()
      ..delayed['Düs'] = Completer<List<ManualLocationCandidate>>();
    await tester.pumpWidget(_app(lookup));
    await _openDialog(tester);
    await _selectGermany(tester);
    await _openCitySearch(tester);
    await tester.enterText(
      find.byKey(const Key('manual-city-search-field')),
      'Dü',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const Key('manual-city-search-field')),
      'Düs',
    );
    await tester.pump(const Duration(milliseconds: 400));
    lookup.delayed['Düs']!.complete(<ManualLocationCandidate>[duesseldorf]);
    await tester.pump();
    lookup.delayed['Dü']!.complete(<ManualLocationCandidate>[]);
    await tester.pump();

    expect(find.text('Düsseldorf'), findsOneWidget);
    expect(find.text('Keine passenden Orte gefunden.'), findsNothing);
  });

  testWidgets('timeout is shown without creating a valid selection', (
    tester,
  ) async {
    final _Lookup lookup = _Lookup()..searchError = TimeoutException('slow');
    await tester.pumpWidget(_app(lookup));
    await _openDialog(tester);
    await _selectGermany(tester);
    await _openCitySearch(tester);
    await tester.enterText(
      find.byKey(const Key('manual-city-search-field')),
      'Düs',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('dauert zu lange'), findsOneWidget);
    await tester.tap(find.byKey(const Key('manual-city-cancel')));
    await tester.pumpAndSettle();
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets(
    'closing during search is safe on iOS and Android',
    (tester) async {
      final Completer<List<ManualLocationCandidate>> pending =
          Completer<List<ManualLocationCandidate>>();
      final _Lookup lookup = _Lookup()..pending = pending;
      await tester.pumpWidget(_app(lookup));
      await _openDialog(tester);
      await _selectGermany(tester);
      await _openCitySearch(tester);
      await tester.enterText(
        find.byKey(const Key('manual-city-search-field')),
        'Düs',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('manual-city-cancel')));
      await tester.pumpAndSettle();
      pending.complete(<ManualLocationCandidate>[duesseldorf]);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('manual-location-cancel')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('Arabic dialog preserves right-to-left direction', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Lookup(), locale: const Locale('ar')));
    await _openDialog(tester);
    final BuildContext context = tester.element(
      find.byType(ManualLocationDialog),
    );
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('locale change while dialog is open keeps route stable', (
    tester,
  ) async {
    final _Lookup lookup = _Lookup();
    await tester.pumpWidget(_app(lookup));
    await _openDialog(tester);
    await _selectGermany(tester);
    await tester.pumpWidget(_app(lookup, locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.byType(ManualLocationDialog), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('city dropdown fits a small phone with keyboard inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(_app(_Lookup()));
    await _openDialog(tester);
    await _selectGermany(tester);
    await _openCitySearch(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manual-city-search-field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
