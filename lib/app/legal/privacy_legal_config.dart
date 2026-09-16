abstract final class PrivacyLegalConfig {
  static const String controllerName = 'Abdulrahman Al Hamidi';
  static const String controllerLocation = 'Düsseldorf, Germany';
  static const String contactEmail = 'ar830222@gmail.com';
  static const String linkedInName = 'Abdulrahman Al Hamidi';

  /// Override the externally hosted policy for a future release with:
  /// `--dart-define=PRIVACY_POLICY_URL=https://your-domain.example/privacy`
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://abalh101.github.io/privacy-policy-salah/',
  );

  static Uri? get privacyPolicyUri {
    final Uri? uri = Uri.tryParse(privacyPolicyUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}
