import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salah_focus/core/notifications/local_notification_service.dart';

class _AppSettings extends GeolocatorPlatform {
  int opened = 0;
  bool available = true;

  @override
  Future<bool> openAppSettings() async {
    opened++;
    return available;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('salahtrack/system_settings');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late GeolocatorPlatform originalPlatform;
  late _AppSettings appSettings;

  setUp(() {
    originalPlatform = GeolocatorPlatform.instance;
    appSettings = _AppSettings();
    GeolocatorPlatform.instance = appSettings;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    GeolocatorPlatform.instance = originalPlatform;
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  for (final exact in [false, true]) {
    Future<void> openSettings() {
      final service = LocalNotificationService();
      return exact
          ? service.openExactAlarmSettings()
          : service.openNotificationSettings();
    }

    test('opens the specific Android settings page (exact: $exact)', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return null;
      });
      await openSettings();
      expect(calls, [
        exact ? 'openExactAlarmSettings' : 'openNotificationSettings',
      ]);
      expect(appSettings.opened, 0);
    });

    test('missing Android bridge opens app details (exact: $exact)', () async {
      await openSettings();
      expect(appSettings.opened, 1);
    });

    test('failed Android launch opens app details (exact: $exact)', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'settings_unavailable');
      });
      await openSettings();
      expect(appSettings.opened, 1);
    });

    test(
      'iOS opens app settings without requesting permission (exact: $exact)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        messenger.setMockMethodCallHandler(channel, (call) async {
          fail('iOS must not call the Android settings bridge');
        });
        await openSettings();
        expect(appSettings.opened, 1);
      },
    );

    test('failed fallback reports an error (exact: $exact)', () async {
      appSettings.available = false;
      await expectLater(
        openSettings(),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'settings_unavailable',
          ),
        ),
      );
    });
  }
}
