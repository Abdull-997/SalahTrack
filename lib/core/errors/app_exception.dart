class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

class LocationException extends AppException {
  const LocationException(super.message, {super.cause});
}

enum LocationSettingsTarget { app, locationServices }

class LocationSettingsException extends LocationException {
  const LocationSettingsException(
    super.message, {
    required this.settingsTarget,
    super.cause,
  });

  final LocationSettingsTarget settingsTarget;
}

class PrayerDataException extends AppException {
  const PrayerDataException(super.message, {super.cause});
}
