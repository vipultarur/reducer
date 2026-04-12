import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:reducer/core/config/app_config.dart';

/// Model representing a specific subscription plan (offer) fetched from the store.
/// 
/// This implementation is 100% dynamic, deriving all text and pricing from 
/// the ProductDetails and SubscriptionOfferDetails objects provided by Google Play.
class PremiumPlan {
  final ProductDetails product;
  
  /// On Android, this is an instance of [SubscriptionOfferDetailsWrapper].
  final dynamic offer;

  const PremiumPlan({
    required this.product,
    this.offer,
  });

  /// Map of ISO 8601 durations to human-readable period names.
  static const Map<String, String> _periodMap = {
    'P1W': 'Weekly',
    'P1M': 'Monthly',
    'P3M': 'Quarterly',
    'P6M': '6 Months',
    'P1Y': 'Yearly',
  };

  /// The raw ISO 8601 billing period (e.g., "P1M", "P1Y") from the last pricing phase.
  String get _billingPeriod {
    try {
      if (offer != null) {
        final phases = offer.pricingPhases;
        if (phases != null && phases.isNotEmpty) {
          // The last phase is typically the recurring one
          return phases.last.billingPeriod ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  /// The human-readable name of the billing cycle (e.g., "Monthly").
  String get periodName {
    if (isYearly) return 'Yearly';
    if (isMonthly) return 'Monthly';
    
    final bp = _billingPeriod.toUpperCase();
    return _periodMap[bp] ?? 'Premium';
  }

  /// Returns the current formatted price text (e.g., "$9.99").
  String get price {
    try {
      if (offer != null) {
        final phases = offer.pricingPhases;
        if (phases != null && phases.isNotEmpty) {
          return phases.last.formattedPrice ?? product.price;
        }
      }
    } catch (_) {}
    return product.price;
  }

  /// Checks if this plan has an active introductory or free trial phase.
  String? get trialPeriod {
    try {
      if (offer != null) {
        final phases = offer.pricingPhases;
        if (phases != null && phases.length > 1) {
          // Typically the first phase(s) are trials/intro prices
          final firstPhase = phases.first;
          if (firstPhase.priceAmountMicros == 0) {
            final period = firstPhase.billingPeriod ?? '';
            if (period == 'P3D') return '3 Days';
            if (period == 'P7D') return '7 Days';
            if (period == 'P1W') return '1 Week';
            if (period == 'P1M') return '1 Month';
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Strictly identifies if this is the yearly plan based on the Base Plan ID in Console.
  bool get isYearly {
    try {
      if (offer != null) {
        return offer.basePlanId == AppConfig.yearlyBasePlanId;
      }
    } catch (_) {}
    return _billingPeriod.toUpperCase() == 'P1Y' || product.id.contains('yearly');
  }

  /// Strictly identifies if this is the monthly plan based on the Base Plan ID in Console.
  bool get isMonthly {
    try {
      if (offer != null) {
        return offer.basePlanId == AppConfig.monthlyBasePlanId;
      }
    } catch (_) {}
    return _billingPeriod.toUpperCase() == 'P1M' || product.id.contains('monthly');
  }

  /// The main title shown on the plan card.
  String get titleText {
    return '$periodName Plan';
  }

  /// Text describing the billing frequency.
  String get billingFrequencyText {
    if (isYearly) return 'Billed yearly';
    if (isMonthly) return 'Billed monthly';
    return 'Billed every ${_billingPeriod.replaceAll('P', '')}';
  }

  /// The combined price/period text (e.g., "$99.99 / year").
  String get periodPriceLabel {
    final suffix = isYearly ? 'year' : (isMonthly ? 'month' : 'period');
    return '$price / $suffix';
  }
}
