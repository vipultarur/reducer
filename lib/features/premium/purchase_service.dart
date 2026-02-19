import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  // Set to true ONLY during local development (never in production)
  static const bool isMockMode = false;

  // ⚠️ IMPORTANT: Replace with your real RevenueCat keys from:
  // https://app.revenuecat.com → Project Settings → API Keys
  static const String _appleApiKey = 'appl_REPLACE_WITH_YOUR_APPLE_REVENUECAT_KEY';
  static const String _googleApiKey = 'goog_REPLACE_WITH_YOUR_GOOGLE_REVENUECAT_KEY';

  static bool _isConfigured = false;

  static Future<void> configure() async {
    if (isMockMode) {
      debugPrint('ℹ️ PurchaseService: Mock mode enabled, skipping configuration');
      return;
    }

    if (_isConfigured) {
      debugPrint('ℹ️ PurchaseService: Already configured');
      return;
    }

    try {
      final apiKey = defaultTargetPlatform == TargetPlatform.iOS
          ? _appleApiKey
          : _googleApiKey;

      final config = PurchasesConfiguration(apiKey);

      // Optional: Set log level for debugging
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
      await Purchases.configure(config);

      _isConfigured = true;
      debugPrint('✅ PurchaseService: RevenueCat configured successfully');
    } catch (e) {
      debugPrint('❌ PurchaseService: Failed to configure RevenueCat: $e');
      rethrow;
    }
  }

  static bool get isConfigured => _isConfigured;
}