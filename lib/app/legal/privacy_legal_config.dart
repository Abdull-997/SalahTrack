abstract final class PrivacyLegalConfig {
  static const String controllerName = 'Abdulrahman Al Hamidi';
  static const String controllerLocation =
      'Universitätsstr. 70\n40225 Düsseldorf\nGermany';
  static const String contactEmail = 'salahfoucus@gmail.com';

  /// Override the externally hosted policy for a future release with:
  /// `--dart-define=PRIVACY_POLICY_URL=https://your-domain.example/privacy`
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://abalh101.github.io/salahtrack-privacy/index.html',
  );

  static Uri? get privacyPolicyUri {
    final Uri? uri = Uri.tryParse(privacyPolicyUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}
