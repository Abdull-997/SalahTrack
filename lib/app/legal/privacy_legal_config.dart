abstract final class PrivacyLegalConfig {
  static const String controllerName = 'Abdulrahman Al Hamidi';
  static const String controllerLocation = 'Düsseldorf, Germany';
  static const String contactEmail = 'ar830222@gmail.com';
  static const String linkedInName = 'Abdulrahman Al Hamidi';

  /// Configure the externally hosted policy for release builds with:
  /// `--dart-define=PRIVACY_POLICY_URL=https://your-domain.example/privacy`
  ///
  /// The value intentionally defaults to empty until a real HTTPS URL exists.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );

  static Uri? get privacyPolicyUri {
    final Uri? uri = Uri.tryParse(privacyPolicyUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}
