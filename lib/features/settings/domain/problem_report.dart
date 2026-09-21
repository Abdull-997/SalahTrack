import 'package:salah_focus/app/legal/privacy_legal_config.dart';
import 'package:salah_focus/app/localization/app_strings.dart';

enum ProblemCategory {
  prayerTimes,
  notifications,
  location,
  qibla,
  prayerTracking,
  ramadan,
  displayLanguage,
  other;

  String get localizationKey => switch (this) {
    prayerTimes => 'reportCategoryPrayerTimes',
    notifications => 'reportCategoryNotifications',
    location => 'reportCategoryLocation',
    qibla => 'reportCategoryQibla',
    prayerTracking => 'reportCategoryPrayerTracking',
    ramadan => 'reportCategoryRamadan',
    displayLanguage => 'reportCategoryDisplayLanguage',
    other => 'reportCategoryOther',
  };
}

class ProblemTechnicalInfo {
  const ProblemTechnicalInfo({
    this.appVersion = '',
    this.buildNumber = '',
    this.platform = '',
    this.osVersion = '',
    this.deviceModel = '',
    required this.languageCode,
  });

  final String appVersion;
  final String buildNumber;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String languageCode;
}

class ProblemReport {
  const ProblemReport({
    required this.category,
    required this.description,
    required this.steps,
    required this.technicalInfo,
  });

  static const String recipient = PrivacyLegalConfig.contactEmail;
  static const String subject = 'SalahTrack – Problem Report';

  final ProblemCategory category;
  final String description;
  final String steps;
  final ProblemTechnicalInfo technicalInfo;

  String body(AppStrings strings) {
    final String unavailable = strings.t('reportNotAvailable');
    String value(String text) =>
        text.trim().isEmpty ? unavailable : text.trim();
    return <String>[
      '${strings.t('reportBodyCategory')}:',
      strings.t(category.localizationKey),
      '',
      '${strings.t('reportBodyDescription')}:',
      description.trim(),
      '',
      '${strings.t('reportBodySteps')}:',
      steps.trim().isEmpty ? strings.t('reportNotProvided') : steps.trim(),
      '',
      '${strings.t('reportTechnicalInformation')}:',
      '${strings.t('reportTechAppVersion')}: ${value(technicalInfo.appVersion)}',
      '${strings.t('reportTechBuild')}: ${value(technicalInfo.buildNumber)}',
      '${strings.t('reportTechPlatform')}: ${value(technicalInfo.platform)}',
      '${strings.t('reportTechOs')}: ${value(technicalInfo.osVersion)}',
      '${strings.t('reportTechDevice')}: ${value(technicalInfo.deviceModel)}',
      '${strings.t('reportTechLanguage')}: ${technicalInfo.languageCode}',
    ].join('\n');
  }

  Uri emailUri(AppStrings strings) => Uri(
    scheme: 'mailto',
    path: recipient,
    queryParameters: <String, String>{
      'subject': subject,
      'body': body(strings),
    },
  );

  String copyText(AppStrings strings) => <String>[
    '${strings.t('reportEmailRecipient')}: $recipient',
    '${strings.t('reportEmailSubject')}: $subject',
    '',
    body(strings),
  ].join('\n');
}
