import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/app/app_providers.dart';
import 'package:salah_focus/app/localization/app_strings.dart';
import 'package:salah_focus/core/errors/app_exception.dart';
import 'package:salah_focus/core/location/location_service.dart';
import 'package:salah_focus/features/onboarding/presentation/onboarding_screen.dart';
import 'package:salah_focus/features/prayer_times/domain/prayer_settings.dart';
import 'package:salah_focus/features/prayer_times/domain/user_location.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:salah_focus/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LocationSpy implements LocationService {
  int requests = 0;

  @override
  Future<UserLocation> currentLocation({
    required String deviceTimezoneId,
    required String languageCode,
  }) async {
    requests++;
    throw const LocationException('Location unavailable in test.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('location is requested only after the disclosure and user tap', (
    tester,
  ) async {
    final _LocationSpy location = _LocationSpy();
    final AppStrings strings = AppStrings(const Locale('en'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialPreferencesProvider.overrideWithValue(
            const AppPreferences(
              prayerSettings: PrayerSettings(),
              localeCode: 'en',
              themeMode: 'system',
              onboardingComplete: false,
            ),
          ),
          locationServiceProvider.overrideWithValue(location),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(strings.t('continue')));
    await tester.tap(find.text(strings.t('continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.t('getStarted')));
    await tester.pumpAndSettle();

    expect(location.requests, 0);
    expect(find.text(strings.t('locationDataDisclosure')), findsOneWidget);
    await tester.tap(find.text(strings.t('useLocation')));
    await tester.pump();
    expect(location.requests, 1);
  });

  testWidgets('onboarding never asks for grace or snooze configuration', (
    tester,
  ) async {
    const UserLocation savedLocation = UserLocation(
      latitude: 51.2277,
      longitude: 6.7735,
      city: 'Düsseldorf',
      country: 'Germany',
      timezoneId: 'Europe/Berlin',
      isAutomatic: false,
    );
    final AppStrings strings = AppStrings(const Locale('en'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialPreferencesProvider.overrideWithValue(
            const AppPreferences(
              prayerSettings: PrayerSettings(),
              location: savedLocation,
              localeCode: 'en',
              themeMode: 'system',
              onboardingComplete: false,
            ),
          ),
          todayPrayerDayProvider.overrideWith((Ref ref) async => null),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/5'), findsOneWidget);
    expect(find.text(strings.t('gracePeriod')), findsNothing);
    expect(find.text(strings.t('snoozeDuration')), findsNothing);
    await tester.ensureVisible(find.text(strings.t('continue')));
    await tester.tap(find.text(strings.t('continue')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(strings.t('getStarted')));
    await tester.tap(find.text(strings.t('getStarted')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(strings.t('continue')));
    await tester.tap(find.text(strings.t('continue')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(strings.t('continue')));
    await tester.tap(find.text(strings.t('continue')));
    await tester.pumpAndSettle();

    expect(find.text('5/5'), findsOneWidget);
    expect(find.text(strings.t('gracePeriod')), findsNothing);
    expect(find.text(strings.t('snoozeDuration')), findsNothing);
  });
}
