import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salah_focus/features/settings/domain/problem_report.dart';
import 'package:url_launcher/url_launcher.dart';

abstract interface class ProblemReportService {
  Future<ProblemTechnicalInfo> loadTechnicalInfo(String languageCode);
  Future<bool> openEmail(Uri uri);
  Future<void> copyText(String text);
}

class PlatformProblemReportService implements ProblemReportService {
  PlatformProblemReportService({
    this._packageInfo,
    DeviceInfoPlugin? deviceInfo,
  }) : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final PackageInfo? _packageInfo;
  final DeviceInfoPlugin _deviceInfo;

  @override
  Future<ProblemTechnicalInfo> loadTechnicalInfo(String languageCode) async {
    String appVersion = '';
    String buildNumber = '';
    try {
      final PackageInfo info = _packageInfo ?? await PackageInfo.fromPlatform();
      appVersion = info.version;
      buildNumber = info.buildNumber;
    } on Object {
      // The report remains usable when package metadata is unavailable.
    }

    String platform = Platform.operatingSystem;
    String osVersion = Platform.operatingSystemVersion;
    String deviceModel = '';
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
        platform = 'Android';
        osVersion = <String>[
          'Android ${info.version.release}',
          'SDK ${info.version.sdkInt}',
        ].join(' · ');
        deviceModel = <String>[
          info.manufacturer,
          info.model,
        ].where((String value) => value.trim().isNotEmpty).join(' ').trim();
      } else if (Platform.isIOS) {
        final IosDeviceInfo info = await _deviceInfo.iosInfo;
        platform = 'iOS';
        osVersion = 'iOS ${info.systemVersion}';
        final String machine = info.utsname.machine.trim();
        deviceModel = machine.isEmpty
            ? info.model.trim()
            : '${info.model.trim()} ($machine)';
      }
    } on Object {
      // Do not block reporting if a platform does not expose model details.
    }

    return ProblemTechnicalInfo(
      appVersion: appVersion,
      buildNumber: buildNumber,
      platform: platform,
      osVersion: osVersion,
      deviceModel: deviceModel,
      languageCode: languageCode,
    );
  }

  @override
  Future<bool> openEmail(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }

  @override
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
