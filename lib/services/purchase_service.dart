import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  // ⚠️ IMPORTANT: Replace with your real RevenueCat Google Play key from:
  // https://app.revenuecat.com → Project Settings → API Keys → Google Play
  static const _apiKey = "goog_REPLACE_WITH_YOUR_REVENUECAT_KEY";
  static const bool isMockMode = false; // Never mock in production

  static bool _isConfigured = false;
  static bool get isConfigured => _isConfigured;

  static Future<void> configure() async {
    if (_isConfigured) return;

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKey);
    } else if (Platform.isIOS) {
      // TODO: Add Apple API key for iOS: https://app.revenuecat.com → Project Settings → API Keys → Apple
      // configuration = PurchasesConfiguration('appl_YOUR_APPLE_KEY');
    }
    
    if (configuration != null) {
      await Purchases.configure(configuration);
      _isConfigured = true;
      debugPrint('✅ PurchaseService: RevenueCat configured successfully');
    } else {
      debugPrint('⚠️ PurchaseService: Platform not supported or API key missing.');
    }
  }

  // Alias for backward compatibility if needed, but main.dart uses configure now
  static Future<void> initialize() => configure();

  static Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      return null;
    }
  }

  static Future<Offerings?> getOfferings() async {
    if (isMockMode || !_isConfigured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      return null;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
    } catch (e) {
      // Handle error
    }
  }
}
