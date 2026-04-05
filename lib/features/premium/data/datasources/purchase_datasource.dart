import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reducer/core/ads/ad_manager.dart';

/// Provider for managing the Premium/Pro status and purchase flow.
final premiumControllerProvider = StateNotifierProvider.autoDispose<PurchaseNotifier, PurchaseState>((ref) => PurchaseNotifier());

class PurchaseState {
  final bool isPro;
  final bool isLoading;
  final List<ProductDetails> availablePackages;
  final ProductDetails? selectedPackage;
  final String errorMessage;

  PurchaseState({
    this.isPro = false,
    this.isLoading = true,
    this.availablePackages = const [],
    this.selectedPackage,
    this.errorMessage = '',
  });

  PurchaseState copyWith({
    bool? isPro,
    bool? isLoading,
    List<ProductDetails>? availablePackages,
    ProductDetails? selectedPackage,
    String? errorMessage,
  }) {
    return PurchaseState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      availablePackages: availablePackages ?? this.availablePackages,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  
  // EXACT PLAY CONSOLE IDs
  static const Set<String> _kProductIds = {'premium_monthly', 'premium_yearly'};

  PurchaseNotifier() : super(PurchaseState()) {
    _init();
  }

  Future<void> _init() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _purchaseSubscription.cancel();
    }, onError: (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    });
    
    if (!mounted) return;
    await fetchOffersAndCheckStatus();
  }

  Future<void> _checkProStatusLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('is_pro_user') ?? false;
    AdManager.isPremium = isPro;
    state = state.copyWith(isPro: isPro);
  }
  
  Future<void> _setProStatusLocally(bool pro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro_user', pro);
    AdManager.isPremium = pro;
    state = state.copyWith(isPro: pro);
  }

  Future<void> fetchOffersAndCheckStatus() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await _checkProStatusLocally();
      
      final bool available = await _iap.isAvailable();
      if (!available) {
        if (!mounted) return;
        state = state.copyWith(errorMessage: "Store is currently unavailable.", isLoading: false);
        return;
      }

      final ProductDetailsResponse response = await _iap.queryProductDetails(_kProductIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("Products not found in store: ${response.notFoundIDs}");
      }
      
      if (response.productDetails.isEmpty) {
        state = state.copyWith(
          errorMessage: "No subscription plans available at this time.", 
          isLoading: false
        );
        return;
      }

      final packages = response.productDetails;
      
      // Sort logic: yearly first
      packages.sort((a, b) {
         if (a.id == 'premium_yearly') return -1;
         if (b.id == 'premium_yearly') return 1;
         return 0;
      });

      if (!mounted) return;
      state = state.copyWith(
         availablePackages: packages, 
         selectedPackage: packages.isNotEmpty ? packages.first : null,
         isLoading: false
      );
      
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: "Failed to load plans: $e", isLoading: false);
    }
  }

  void selectPackage(ProductDetails package) {
    state = state.copyWith(selectedPackage: package);
  }

  Future<bool> purchaseSelectedPackage() async {
    if (state.selectedPackage == null) {
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: state.selectedPackage!);
      // buyNonConsumable acts for subscriptions similarly in typical plugin usage if not verifying backend,
      // but 'buyNonConsumable' is required on Android to acknowledge Subscriptions properly over buyConsumable
      final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return success; // Actual success triggers via stream
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Failed to restore: $e");
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        state = state.copyWith(isLoading: true);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
           debugPrint("Purchase error: ${purchaseDetails.error}");
           state = state.copyWith(isLoading: false, errorMessage: purchaseDetails.error?.message ?? "Error occurred");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
           
           if (purchaseDetails.pendingCompletePurchase) {
             await _iap.completePurchase(purchaseDetails);
           }
           
           if (_kProductIds.contains(purchaseDetails.productID)) {
             await _setProStatusLocally(true);
             AdManager().disposeAll();
           }
        }
        
        state = state.copyWith(isLoading: false);
      }
    }
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }
}
