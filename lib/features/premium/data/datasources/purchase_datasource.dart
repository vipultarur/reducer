import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/features/premium/domain/models/premium_plan.dart';

import 'package:reducer/core/config/app_config.dart';
import 'package:reducer/features/auth/presentation/providers/auth_providers.dart';
import 'package:reducer/core/services/notification_service.dart';

// ─── Keys for SecureStorage ─────────────────────────────────────────────────
const String _kSecIsPro = 'is_pro_user';
const String _kSecProVerifiedAt = 'pro_verified_at_ms';

/// How often to re-validate the subscription against the store (hours).
const int _kRevalidationIntervalHours = 24;

/// Provider for managing the Premium/Pro status and purchase flow.
final premiumControllerProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>(
      (ref) => PurchaseNotifier(ref),
    );

// ─── State ──────────────────────────────────────────────────────────────────
class PurchaseState {
  final bool isPro;
  final bool isLoading;
  final List<PremiumPlan> availablePackages;
  final PremiumPlan? selectedPackage;
  final String errorMessage;

  /// Informational message shown after a successful purchase or restore.
  final String successMessage;

  PurchaseState({
    this.isPro = false,
    this.isLoading = true,
    this.availablePackages = const [],
    this.selectedPackage,
    this.errorMessage = '',
    this.successMessage = '',
  });

  PurchaseState copyWith({
    bool? isPro,
    bool? isLoading,
    List<PremiumPlan>? availablePackages,
    PremiumPlan? selectedPackage,
    String? errorMessage,
    String? successMessage,
  }) {
    return PurchaseState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      availablePackages: availablePackages ?? this.availablePackages,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _purchaseInProgress = false;

  PurchaseNotifier(this._ref) : super(PurchaseState()) {
    _init();
  }

  User? get _currentUser => _ref.read(authServiceProvider).currentUser;
  bool get _hasEligiblePremiumAccount {
    final user = _currentUser;
    return user != null && !user.isAnonymous;
  }

  // ── Initialization ──────────────────────────────────────────────────────

  Future<void> _init() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (Object error) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      },
    );

    await fetchOffersAndCheckStatus();
  }

  // ── Secure Pro Status ───────────────────────────────────────────────────

  /// Generates a cryptographically secure integrity hash based on user data
  String _generateIntegrityHash(String uid) {
    // 2026 Production Standard: HMAC-SHA256 with a project-specific salt
    final key = utf8.encode('reducer_secure_salt_v1_2026_premium_hardening');
    final bytes = utf8.encode(uid);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  Future<void> _checkProStatusLocally() async {
    final user = _currentUser;
    if (user == null || user.isAnonymous) {
      AdManager.updatePremiumStatus(false);
      if (!mounted) return;
      state = state.copyWith(isPro: false);
      return;
    }

    final String? isProStr = await _secureStorage.read(key: _kSecIsPro);
    final isPro = isProStr == 'true';

    // Verify Integrity Hash to prevent storage editing
    final String? storedHash = await _secureStorage.read(key: 'pro_integrity_v1');
    final expectedHash = _generateIntegrityHash(user.uid);

    if (isPro && storedHash != expectedHash) {
      debugPrint('[Security] ⚠️ Local Pro status integrity check FAILED. Resetting.');
      await clearProStatus();
      return;
    }

    if (isPro) {
      final String? lastVerifiedMsStr = await _secureStorage.read(
        key: _kSecProVerifiedAt,
      );
      final lastVerifiedMs = int.tryParse(lastVerifiedMsStr ?? '') ?? 0;
      final timeSinceMs =
          DateTime.now().millisecondsSinceEpoch - lastVerifiedMs;
      final hoursSince = timeSinceMs / (1000 * 60 * 60);

      if (hoursSince > _kRevalidationIntervalHours) {
        debugPrint(
          '[Purchase] Pro-status stale (${hoursSince.toStringAsFixed(1)}h), re-validating...',
        );
        unawaited(fetchOffersAndCheckStatus());
      }
    }

    AdManager.updatePremiumStatus(isPro);
    if (!mounted) return;
    state = state.copyWith(isPro: isPro);
  }

  Future<void> _setProStatusLocally(bool pro) async {
    final user = _currentUser;
    if (user == null) return;

    await _secureStorage.write(key: _kSecIsPro, value: pro ? 'true' : 'false');
    if (pro) {
      await _secureStorage.write(
        key: _kSecProVerifiedAt,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      // Write Integrity Hash
      await _secureStorage.write(
        key: 'pro_integrity_v1',
        value: _generateIntegrityHash(user.uid),
      );
    } else {
      await _secureStorage.delete(key: _kSecProVerifiedAt);
      await _secureStorage.delete(key: 'pro_integrity_v1');
    }
    
    AdManager.updatePremiumStatus(pro);
    if (!mounted) return;
    state = state.copyWith(isPro: pro);
  }

  Future<void> clearProStatus() async {
    await _setProStatusLocally(false);
  }

  // ── Fetch Offers ────────────────────────────────────────────────────────

  Future<void> fetchOffersAndCheckStatus() async {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
      successMessage: '',
    );

    try {
      await _checkProStatusLocally();

      final bool available = await _iap.isAvailable();
      if (!available) {
        if (!mounted) return;
        state = state.copyWith(
          errorMessage: 'Store unavailable.',
          isLoading: false,
        );
        return;
      }

      // Query ONLY the parent product ID(s) — NOT base plan IDs.
      // Base plans are returned as subscriptionOfferDetails within each product.
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        AppConfig.productIds,
      );

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          '[Purchase] ❌ Products not found: ${response.notFoundIDs}. '
          'Check your Google Play Console Product IDs. '
          'Queried: ${AppConfig.productIds}',
        );
      }

      if (response.error != null) {
        if (!mounted) return;
        state = state.copyWith(
          errorMessage: 'Store error: ${response.error?.message}',
          isLoading: false,
        );
        return;
      }

      final packages = <PremiumPlan>[];
      final seenPlanIds = <String>{};

      for (final product in response.productDetails) {
        if (product is GooglePlayProductDetails) {
          final offers = product.productDetails.subscriptionOfferDetails;
          if (offers != null && offers.isNotEmpty) {
            for (final offer in offers) {
              // Create a properly typed PremiumPlan for each base plan offer.
              final plan = PremiumPlan(product: product, offer: offer);

              // Unique key for preventing duplicate UI entries
              final planId =
                  '${product.id}_${offer.basePlanId}_${offer.offerId ?? "base"}';

              if (!seenPlanIds.contains(planId)) {
                packages.add(plan);
                seenPlanIds.add(planId);
                debugPrint(
                  '🔹 Plan Loaded: ${plan.titleText} '
                  '| Price: ${plan.price} '
                  '| BasePlan: ${offer.basePlanId} '
                  '| Offer: ${offer.offerId ?? "Standard"} '
                  '| OfferToken: ${offer.offerIdToken.substring(0, 20)}...',
                );
              }
            }
          } else {
            debugPrint(
              '[Purchase] ⚠️ Product ${product.id} has no subscriptionOfferDetails. '
              'Check Base Plan status in Google Play Console.',
            );
            // No offer details — add as fallback (no typed offer)
            packages.add(PremiumPlan(product: product));
          }
        } else {
          // Non-Android platform fallback
          packages.add(PremiumPlan(product: product));
        }
      }

      // Sort: Yearly plans first for better conversion
      packages.sort((a, b) {
        if (a.isYearly && !b.isYearly) return -1;
        if (!a.isYearly && b.isYearly) return 1;
        return 0;
      });

      debugPrint('[Purchase] ✅ Total plans loaded: ${packages.length}');
      for (final p in packages) {
        debugPrint('  → ${p.titleText}: ${p.price} (${p.offer?.basePlanId ?? "no-offer"})');
      }

      if (!mounted) return;
      state = state.copyWith(
        availablePackages: packages,
        selectedPackage: packages.isNotEmpty ? packages.first : null,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Purchase] Fetch Error: $e');
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: 'Failed to load plans: $e',
        isLoading: false,
      );
    }
  }

  void selectPackage(PremiumPlan package) {
    state = state.copyWith(
      selectedPackage: package,
      errorMessage: '',
      successMessage: '',
    );
  }

  // ── Purchase ────────────────────────────────────────────────────────────

  /// Purchases the selected package.
  ///
  /// IMPORTANT: For Google Play Billing 5+, the [offerToken] is mandatory for subscriptions.
  /// We use the offer-specific token (offerIdToken) to ensure the correct base plan is purchased.
  Future<void> purchaseSelectedPackage() async {
    if (state.selectedPackage == null || _purchaseInProgress) return;
    if (!_hasEligiblePremiumAccount) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please login to unlock Premium',
        successMessage: '',
      );
      return;
    }

    final plan = state.selectedPackage!;
    _purchaseInProgress = true;
    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
      successMessage: '',
    );

    try {
      PurchaseParam purchaseParam;

      if (Platform.isAndroid) {
        final String? offerToken = _resolveAndroidOfferToken(plan);

        if (offerToken == null || offerToken.isEmpty) {
          throw Exception(
            'Missing offerToken for Android subscription "${plan.offer?.basePlanId ?? 'unknown'}". '
            'Ensure base plans are active in Google Play Console.',
          );
        }

        debugPrint('[Purchase] Purchasing with offerToken: ${offerToken.substring(0, 20)}...');

        purchaseParam = GooglePlayPurchaseParam(
          productDetails: plan.product,
          offerToken: offerToken,
        );
      } else {
        purchaseParam = PurchaseParam(productDetails: plan.product);
      }

      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('[Purchase] Initiation Failed: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Purchase failed: ${e.toString()}',
      );
    } finally {
      _purchaseInProgress = false;
    }
  }

  /// Resolve Google Play subscription offer token for the selected plan.
  ///
  /// PRIORITY ORDER:
  /// 1. The specific offer's offerIdToken (correct for the selected base plan)
  /// 2. The product-level offerToken (fallback, may be for a different base plan)
  String? _resolveAndroidOfferToken(PremiumPlan plan) {
    // 1. Use the specific offer's token — this is the correct token for the
    //    selected base plan and ensures the right plan is purchased.
    if (plan.offer != null) {
      final token = plan.offer!.offerIdToken;
      if (token.isNotEmpty) {
        debugPrint('[Purchase] Using offer-specific token for: ${plan.offer!.basePlanId}');
        return token;
      }
    }

    // 2. Fallback: product-level offer token
    try {
      if (plan.product is GooglePlayProductDetails) {
        final details = plan.product as GooglePlayProductDetails;
        final token = details.offerToken;
        if (token != null && token.isNotEmpty) {
          debugPrint('[Purchase] ⚠️ Falling back to product-level offerToken');
          return token;
        }
      }
    } catch (_) {}

    debugPrint('[Purchase] ❌ No offerToken found for plan: ${plan.titleText}');
    return null;
  }

  // ── Restore ─────────────────────────────────────────────────────────────

  Future<void> restorePurchases() async {
    if (!_hasEligiblePremiumAccount) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please login to unlock Premium',
        successMessage: '',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
      successMessage: '',
    );
    try {
      debugPrint('[Purchase] Restoring...');
      await _iap.restorePurchases();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Restore failed: $e',
      );
    }
  }

  // ── Stream Listener ─────────────────────────────────────────────────────

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          if (!mounted) return;
          state = state.copyWith(isLoading: true, errorMessage: '');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          debugPrint('[Purchase] ❌ Error: ${purchaseDetails.error}');
          if (!mounted) return;
          state = state.copyWith(
            isLoading: false,
            errorMessage: purchaseDetails.error?.message ?? 'Purchase error.',
          );
          break;
        case PurchaseStatus.canceled:
          debugPrint('[Purchase] User canceled.');
          if (!mounted) return;
          state = state.copyWith(isLoading: false, errorMessage: '');
          break;
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails details) async {
    try {
      if (details.pendingCompletePurchase) {
        await _iap.completePurchase(details);
      }

      // Verify this is a product we recognize
      if (details.productID == AppConfig.productId ||
          AppConfig.productIds.contains(details.productID)) {
        await _setProStatusLocally(true);
        await _syncSubscriptionToFirestore(details);
      }

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        successMessage: details.status == PurchaseStatus.restored
            ? 'Restored Successfully!'
            : 'Welcome to Premium! 🎉',
      );

      // Show congratulations notification
      if (details.status == PurchaseStatus.purchased) {
        debugPrint('[PurchaseNotifier] Successful purchase, triggering notification');
        Future.delayed(const Duration(milliseconds: 500), () {
          NotificationService().showNotification(
            id: 2,
            title: 'Congratulations! 💎',
            body: 'You are now a Premium member. Enjoy all the Pro features!',
          );
        });
      }
    } catch (e) {
      debugPrint('[Purchase] Handle Success Error: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Verification failed.',
      );
    }
  }

  Future<void> _syncSubscriptionToFirestore(PurchaseDetails details) async {
    try {
      final user = _ref.read(authServiceProvider).currentUser;
      if (user == null || user.isAnonymous) return;

      // OPTIMIZATION: Avoid redundant writes if status is already synced
      final String? lastSyncedToken = await _secureStorage.read(key: 'last_synced_purchase_token');
      final currentToken = details.verificationData.serverVerificationData;
      
      if (lastSyncedToken == currentToken && details.status != PurchaseStatus.purchased) {
        debugPrint('[Purchase] Skipping Firestore sync - token already current.');
        return;
      }

      final Map<String, dynamic> subData = {
        'subscriptionStatus': 'premium',
        'productId': details.productID,
        'purchaseToken': currentToken,
        'orderId': details.purchaseID,
        'subscriptionStartDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Map the selected plan details to Firestore
      final selectedPlan = state.selectedPackage;
      if (selectedPlan != null) {
        // Save raw numeric value for easier calculations/reporting
        subData['priceAmount'] = selectedPlan.priceAmountMicros / 1000000.0;
        subData['priceCurrencyCode'] = selectedPlan.product.currencyCode;
        subData['billingPeriod'] = selectedPlan.isYearly ? 'yearly' : (selectedPlan.isMonthly ? 'monthly' : 'test');
        subData['basePlanId'] = selectedPlan.offer?.basePlanId ?? 'unknown';
      }

      await _ref.read(userServiceProvider).updateSubscription(user.uid, subData);
      await _secureStorage.write(key: 'last_synced_purchase_token', value: currentToken);
      
      debugPrint('[Purchase] ✅ Firestore synced successfully.');
    } catch (e) {
      debugPrint('[Purchase] ❌ Firestore sync error: $e');
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
