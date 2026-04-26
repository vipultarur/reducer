import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._();
  factory ReviewService() => _instance;
  ReviewService._();

  static const String _countKey = 'compression_success_count';
  static const int _threshold = 5;

  /// Increments the compression count and triggers a review prompt if threshold is met.
  Future<void> logSuccessAndCheckReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_countKey) ?? 0;
      final newCount = currentCount + 1;
      await prefs.setInt(_countKey, newCount);

      if (newCount >= _threshold) {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          debugPrint('[ReviewService] Threshold met, requesting review');
          await inAppReview.requestReview();
          // Reset after trigger so it cycles again
          await prefs.setInt(_countKey, 0);
        }
      }
    } catch (e) {
      debugPrint('[ReviewService] Error: $e');
    }
  }

  /// Manually triggers a review request.
  Future<void> requestReview() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('[ReviewService] requestReview Error: $e');
    }
  }

  /// Opens the store listing for the app.
  Future<void> openStoreListing() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      await inAppReview.openStoreListing();
    } catch (e) {
      debugPrint('[ReviewService] openStoreListing Error: $e');
    }
  }
}
