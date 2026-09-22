import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salah_focus/core/platform/application_locale.dart';
import 'package:salah_focus/features/settings/application/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('salahtrack/system_settings');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'clears a previously forced Android language to follow the OS',
    () async {
      await ApplicationLocale.followSystem();
      expect(calls.single.method, 'setApplicationLocale');
      expect(calls.single.arguments, '');
    },
  );

  test(
    'changing the in-app language does not force the launcher language',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      for (final language in ['en', 'ar', 'de']) {
        await container
            .read(settingsControllerProvider.notifier)
            .setLocale(language);
        expect(container.read(settingsControllerProvider).localeCode, language);
      }
      expect(calls, isEmpty);
    },
  );

  test(
    'iOS relies on localized bundle names without an Android call',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await ApplicationLocale.followSystem();
      expect(calls, isEmpty);
    },
  );

  test('an older build without the locale bridge still starts', () async {
    messenger.setMockMethodCallHandler(channel, null);
    await expectLater(ApplicationLocale.followSystem(), completes);
  });
}
