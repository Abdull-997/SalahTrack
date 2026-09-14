import 'package:salah_focus/features/settings/data/settings_repository.dart';

class ReviewRequestPolicy {
  const ReviewRequestPolicy._();

  static const Duration minimumAge = Duration(hours: 72);

  static bool isEligible(AppPreferences preferences, DateTime nowUtc) {
    final DateTime? firstLaunch = preferences.firstLaunchAtUtc;
    return preferences.onboardingComplete &&
        !preferences.reviewRequestAttempted &&
        firstLaunch != null &&
        !nowUtc.toUtc().isBefore(firstLaunch.toUtc().add(minimumAge));
  }
}
