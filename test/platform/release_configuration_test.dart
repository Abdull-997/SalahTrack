import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test(
    'Android release configuration targets API 36 without broad permissions',
    () {
      final String appGradle = _read('android/app/build.gradle.kts');
      final String settingsGradle = _read('android/settings.gradle.kts');
      final String wrapper = _read(
        'android/gradle/wrapper/gradle-wrapper.properties',
      );
      final String manifest = _read('android/app/src/main/AndroidManifest.xml');

      expect(appGradle, contains('compileSdk = 36'));
      expect(appGradle, contains('targetSdk = 36'));
      expect(appGradle, contains('minSdk = flutter.minSdkVersion'));
      expect(appGradle, contains('JavaVersion.VERSION_17'));
      expect(appGradle, contains('JvmTarget.JVM_17'));
      expect(appGradle, contains('namespace = "com.salahtrack.app"'));
      expect(appGradle, contains('applicationId = "com.salahtrack.app"'));
      expect(
        settingsGradle,
        contains('com.android.application") version "9.1.0'),
      );
      expect(
        settingsGradle,
        contains('org.jetbrains.kotlin.android") version "2.4.0'),
      );
      expect(wrapper, contains('gradle-9.3.1-all.zip'));
      expect(manifest, contains('android:enableOnBackInvokedCallback="true"'));
      expect(manifest, isNot(contains('android:screenOrientation=')));
      expect(manifest, isNot(contains('android:resizeableActivity="false"')));
      expect(manifest, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
      expect(manifest, isNot(contains('USE_EXACT_ALARM')));
      expect(
        manifest,
        isNot(
          contains(
            'USE_FULL_'
            'SCREEN_INTENT',
          ),
        ),
      );
      expect(manifest, isNot(contains('SYSTEM_ALERT_WINDOW')));
      expect(manifest, isNot(contains('BIND_ACCESSIBILITY_SERVICE')));
      expect(manifest, isNot(contains('PACKAGE_USAGE_STATS')));
      expect(manifest, isNot(contains('BIND_VPN_SERVICE')));
      expect(manifest, isNot(contains('BIND_DEVICE_ADMIN')));
      expect(manifest, isNot(contains('QUERY_ALL_PACKAGES')));
    },
  );

  test('iOS release configuration remains foreground-location only', () {
    final String project = _read('ios/Runner.xcodeproj/project.pbxproj');
    final String info = _read('ios/Runner/Info.plist');
    final String entitlements = _read('ios/Runner/Runner.entitlements');

    expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 16.0'));
    expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = com.salahtrack.app'));
    expect(info, contains('<key>NSLocationWhenInUseUsageDescription</key>'));
    expect(info, isNot(contains('NSLocationAlways')));
    expect(info, isNot(contains('UIBackgroundModes')));
    expect(info, isNot(contains('NSUserTrackingUsageDescription')));
    expect(
      entitlements,
      contains('com.apple.developer.usernotifications.time-sensitive'),
    );
    expect(
      entitlements,
      isNot(contains('com.apple.developer.family-controls')),
    );
    expect(
      entitlements,
      isNot(contains('com.apple.security.application-groups')),
    );
  });

  test('iOS CI is pinned to the submission toolchain and validates tests', () {
    final String workflow = _read('.github/workflows/build_ios.yml');
    expect(workflow, contains('runs-on: macos-26'));
    expect(workflow, contains("flutter-version: '3.47.4'"));
    expect(workflow, contains('flutter analyze'));
    expect(workflow, contains('flutter test'));
    expect(workflow, contains('flutter build ipa'));
    expect(workflow, contains('--export-options-plist'));
    expect(workflow, contains('app-store-connect'));
    expect(workflow, contains('IOS_CERTIFICATE_BASE64'));
    expect(workflow, contains('IOS_PROVISIONING_PROFILE_BASE64'));
    expect(workflow, isNot(contains('--no-codesign')));
    expect(workflow, isNot(contains('tool/bootstrap')));
  });
}
