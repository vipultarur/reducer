class AppConfig {
  static const String appName = 'Reducer';
  
  // Subscription Configuration
  /// The parent subscription product ID configured in Google Play Console.
  static const String productId = 'ai_image_pro';

  /// Base Plan IDs (children of the product, configured under the subscription in Console).
  static const String monthlyBasePlanId = 'monthly-plan';
  static const String testplan = 'test-plan';
  static const String yearlyBasePlanId = 'yearly-plan';
  
  /// Product IDs to query from the store via `queryProductDetails`.
  /// IMPORTANT: Only include actual product IDs here, NOT base plan IDs.
  /// Base plans are returned as `subscriptionOfferDetails` within each product.
  static const Set<String> productIds = {
    productId,
  };

  /// All recognized base plan IDs for validation purposes.
  static const Set<String> basePlanIds = {
    monthlyBasePlanId,
    yearlyBasePlanId,
    testplan,
  };

  // Firebase Collection Names
  static const String usersCollection = 'users';
}
