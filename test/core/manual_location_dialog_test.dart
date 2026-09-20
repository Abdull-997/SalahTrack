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
  final List<ManualLocationCandidate> results = [];
  ManualLocationCandidate? fallback;
  Completer<List<ManualLocationCandidate>>? pending;
  final Map<String, Completer<List<ManualLocationCandidate>>> delayed = {};
  Object? searchError;
  String? lastQuery;
  String? lastCountry;

  @override
  Future<List<ManualLocationCandidate>> search({
    required String query,
    required String countryCode,
    required String countryName,
    required String timezoneId,
    String languageCode = 'en',
  }) {
    lastQuery = query;
    lastCountry = countryCode;
    if (searchError != null) return Future.error(searchError!);
    return delayed[query]?.future ?? pending?.future ?? Future.value(results);
  }

  @override
  Future<ManualLocationCandidate?> nearby({
    required String query,
    required String countryCode,
    required String countryName,
    required String timezoneId,
    String languageCode = 'en',
  }) async => fallback;
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

Widget _app(
  _Lookup lookup, {
  Locale locale = const Locale('de'),
  ValueChanged<UserLocation?>? onResult,
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppStrings.supportedLocales,
  localizationsDelegates: const [
    AppStrings.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () async {
            final result = await showDialog<UserLocation>(
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

Future<void> _selectGermany(WidgetTester tester) async {
  await tester.tap(find.text('Land suchen'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('country-search-field')), 'De');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Deutschland').last);
  await tester.pumpAndSettle();
}

void main() {
  test('all supported locales have manual location text and country names', () {
    for (final locale in AppStrings.supportedLocales) {
      final code = locale.languageCode;
      expect(
        manualLocationTranslations[code]?.keys,
        containsAll(manualLocationTranslations['en']!.keys),
      );
      expect(countryNames[code]?['DE'], isNotEmpty);
      expect(countryNames[code]?['PK'], isNotEmpty);
      expect(countryNames[code]?['TR'], isNotEmpty);
    }
  });

  testWidgets('country then dynamic city suggestion enables saving', (
    tester,
  ) async {
    final lookup = _Lookup()..results.add(duesseldorf);
    UserLocation? saved;
    await tester.pumpWidget(_app(lookup, onResult: (value) => saved = value));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Speichern'))
          .onPressed,
      isNull,
    );
    await _selectGermany(tester);
    await tester.enterText(find.byKey(const Key('manual-city-field')), 'Düs');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(lookup.lastQuery, 'Düs');
    expect(lookup.lastCountry, 'DE');
    expect(find.text('Nordrhein-Westfalen, Deutschland'), findsOneWidget);
    await tester.tap(find.text('Düsseldorf').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(saved?.latitude, 51.2277);
  });

  testWidgets('nearby city needs explicit confirmation', (tester) async {
    final lookup = _Lookup()
      ..fallback = const ManualLocationCandidate(
        location: UserLocation(
          latitude: 51.2,
          longitude: 6.7,
          city: 'Neuss',
          country: 'Deutschland',
          timezoneId: 'Europe/Berlin',
          isAutomatic: false,
        ),
        region: 'Nordrhein-Westfalen',
        countryCode: 'DE',
      );
    await tester.pumpWidget(_app(lookup));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _selectGermany(tester);
    await tester.enterText(
      find.byKey(const Key('manual-city-field')),
      'Kaarst',
    );
    await tester.pump();
    await tester.tap(find.text('Eingabe prüfen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Neuss, Deutschland'), findsOneWidget);
    await tester.tap(find.text('Andere Stadt wählen'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Speichern'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Eingabe prüfen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neuss verwenden'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Speichern'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'closing during async search and reopening does not update unmounted state',
    (tester) async {
      final lookup = _Lookup()
        ..pending = Completer<List<ManualLocationCandidate>>();
      await tester.pumpWidget(_app(lookup));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await _selectGermany(tester);
      await tester.enterText(find.byKey(const Key('manual-city-field')), 'Düs');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      lookup.pending!.complete([duesseldorf]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('older search results never replace newer results', (
    tester,
  ) async {
    final lookup = _Lookup()
      ..delayed['Dü'] = Completer<List<ManualLocationCandidate>>()
      ..delayed['Düs'] = Completer<List<ManualLocationCandidate>>();
    await tester.pumpWidget(_app(lookup));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _selectGermany(tester);
    await tester.enterText(find.byKey(const Key('manual-city-field')), 'Dü');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const Key('manual-city-field')), 'Düs');
    await tester.pump(const Duration(milliseconds: 400));
    lookup.delayed['Düs']!.complete([duesseldorf]);
    await tester.pump();
    lookup.delayed['Dü']!.complete([]);
    await tester.pump();
    expect(find.text('Düsseldorf'), findsOneWidget);
    expect(find.text('Keine passenden Orte gefunden.'), findsNothing);
  });

  testWidgets('empty search and unresolved place keep save disabled', (
    tester,
  ) async {
    final lookup = _Lookup();
    await tester.pumpWidget(_app(lookup));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _selectGermany(tester);
    await tester.enterText(
      find.byKey(const Key('manual-city-field')),
      'Unknown',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Keine passenden Orte gefunden.'), findsOneWidget);
    await tester.tap(find.text('Eingabe prüfen'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Dieser Ort konnte nicht gefunden werden'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Speichern'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('timeout is shown without enabling save', (tester) async {
    final lookup = _Lookup()..searchError = TimeoutException('slow');
    await tester.pumpWidget(_app(lookup));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _selectGermany(tester);
    await tester.enterText(find.byKey(const Key('manual-city-field')), 'Düs');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.textContaining('dauert zu lange'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Speichern'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('Arabic dialog uses right-to-left direction', (tester) async {
    await tester.pumpWidget(_app(_Lookup(), locale: const Locale('ar')));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ManualLocationDialog));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('locale change while dialog is open keeps route stable', (
    tester,
  ) async {
    final lookup = _Lookup();
    await tester.pumpWidget(_app(lookup));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _selectGermany(tester);
    await tester.pumpWidget(_app(lookup, locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.byType(ManualLocationDialog), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog fits a small phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(_app(_Lookup()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(ManualLocationDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small phone dialog remains usable with keyboard inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(_app(_Lookup()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(ManualLocationDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
