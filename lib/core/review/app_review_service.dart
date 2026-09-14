import 'package:in_app_review/in_app_review.dart';

abstract interface class AppReviewService {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class PlatformAppReviewService implements AppReviewService {
  PlatformAppReviewService([InAppReview? review])
    : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<bool> isAvailable() => _review.isAvailable();

  @override
  Future<void> requestReview() => _review.requestReview();
}
