import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../ads/ad_service.dart';
import '../services/purchase_service.dart';
import '../ads/remote_config_service.dart';
import '../services/connectivity_service.dart';
import 'package:reducer/core/ads/ad_manager.dart';

class PremiumState {
  final bool isPro;
  final bool isLoading;
  final List<Package> availablePackages;
  final Package? selectedPackage;
  final String? errorMessage;
  final int retryCount;
  final bool hasAttemptedFetch;

  PremiumState({
    required this.isPro,
    required this.isLoading,
    required this.availablePackages,
    this.selectedPackage,
    this.errorMessage,
    this.retryCount = 0,
    this.hasAttemptedFetch = false,
  });

  PremiumState copyWith({
    bool? isPro,
    bool? isLoading,
    List<Package>? availablePackages,
    Package? selectedPackage,
    String? errorMessage,
    int? retryCount,
    bool? hasAttemptedFetch,
  }) {
    return PremiumState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      availablePackages: availablePackages ?? this.availablePackages,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      hasAttemptedFetch: hasAttemptedFetch ?? this.hasAttemptedFetch,
    );
  }
}

final premiumProvider =
StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<PremiumState> {
  PremiumNotifier()
      : super(PremiumState(
    isPro: false,
    isLoading: true,
    availablePackages: [],
    errorMessage: null,
  )) {
    _init();
  }

  final _connectivity = ConnectivityService();
  final _remoteConfig = RemoteConfigService();

  /// Ensures RevenueCat is configured before any SDK call.
  /// Calls PurchaseService.configure() if not yet done.
  Future<void> _ensureConfigured() async {
    if (PurchaseService.isConfigured) return;
    debugPrint('⚙️ PremiumNotifier: RevenueCat not yet configured — configuring now...');
    await PurchaseService.configure();
  }

  Future<void> _init() async {
    if (PurchaseService.isMockMode) {
      fetchOffersAndCheckStatus();
      return;
    }

    try {
      // Always ensure SDK is ready before registering listeners or fetching
      await _ensureConfigured();

      // Listen for subscription status changes pushed by RevenueCat
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateStatus(customerInfo);
      });

      // Retry when connectivity is restored
      _connectivity.isConnected.addListener(() {
        if (_connectivity.isConnected.value &&
            state.availablePackages.isEmpty &&
            state.hasAttemptedFetch &&
            state.retryCount < 3) {
          debugPrint('🔄 Connectivity restored — retrying purchase fetch');
          fetchOffersAndCheckStatus();
        }
      });

      fetchOffersAndCheckStatus();
    } catch (e) {
      debugPrint('❌ PremiumNotifier._init failed: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Initialization failed: ${e.toString()}',
        );
      }
    }
  }

  Future<void> fetchOffersAndCheckStatus() async {
    // ── Mock mode ──────────────────────────────────────────────────────────
    if (PurchaseService.isMockMode) {
      debugPrint('ℹ️ PremiumNotifier: Running in Mock Mode');
      state = state.copyWith(isLoading: true, errorMessage: null);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        state = state.copyWith(isLoading: false, isPro: false);
        AdService.isPremium = false;
      }
      return;
    }

    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        hasAttemptedFetch: true,
        retryCount: state.retryCount + 1,
      );

      // ── Guard: ensure SDK is ready ───────────────────────────────────────
      await _ensureConfigured();

      // ── Guard: check connectivity ────────────────────────────────────────
      if (!_connectivity.currentStatus) {
        if (mounted) {
          state = state.copyWith(
            errorMessage: 'No internet connection. Please check your network.',
            isLoading: false,
          );
        }
        debugPrint('❌ No internet connection');
        return;
      }

      debugPrint('🔄 Fetching offerings (attempt ${state.retryCount})...');

      // ── Fetch offerings ──────────────────────────────────────────────────
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null ||
          offerings.current!.availablePackages.isEmpty) {
        if (mounted) {
          state = state.copyWith(
            errorMessage: 'No subscription plans available at this time.',
            isLoading: false,
          );
        }
        debugPrint('⚠️ No offerings available');
        return;
      }

      // ── Filter & sort packages ───────────────────────────────────────────
      final packages = offerings.current!.availablePackages
          .where(_isSubscriptionPackage)
          .toList();

      // Sort: Yearly > 6-month > 3-month > Monthly > Weekly
      packages.sort((a, b) {
        int score(Package p) {
          if (_isYearly(p)) return 5;
          if (p.packageType == PackageType.sixMonth) return 4;
          if (p.packageType == PackageType.threeMonth) return 3;
          if (p.packageType == PackageType.monthly) return 2;
          if (p.packageType == PackageType.weekly) return 1;
          return 0;
        }
        return score(b).compareTo(score(a));
      });

      debugPrint('✅ Packages loaded (${packages.length})');

      // ── Select default package ───────────────────────────────────────────
      Package? selectedPackage;
      if (packages.isNotEmpty) {
        final preferYearly = _remoteConfig
            .getBool(RemoteConfigService.defaultYearlySelectPackage);
        if (preferYearly) {
          selectedPackage = packages.first;
          debugPrint('📌 Selected yearly package by default');
        } else {
          selectedPackage = packages.firstWhere(
                (p) => !_isYearly(p),
            orElse: () => packages.first,
          );
          debugPrint('📌 Selected non-yearly package by default');
        }
      }

      // ── Check subscription status ────────────────────────────────────────
      final customerInfo = await Purchases.getCustomerInfo();
      final isPro = customerInfo.entitlements.active.isNotEmpty;
      debugPrint('👤 User Pro Status: $isPro');

      if (mounted) {
        state = state.copyWith(
          availablePackages: packages,
          selectedPackage: selectedPackage,
          isPro: isPro,
          isLoading: false,
          retryCount: 0, // Reset on success
        );
        AdService.isPremium = isPro;
        AdManager.isPremium = isPro;
      }

      debugPrint('✅ PremiumNotifier initialized successfully');
    } on PlatformException catch (e) {
      PurchasesErrorCode errorCode;
      try {
        errorCode = PurchasesErrorHelper.getErrorCode(e);
      } catch (_) {
        errorCode = PurchasesErrorCode.unknownError;
      }

      debugPrint(
          '❌ Purchase Error (PlatformException): $errorCode - ${e.message}');

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load plans: ${_getErrorMessage(errorCode)}',
        );
      }

      // Retry for recoverable errors
      if (_shouldRetry(errorCode) && state.retryCount < 3) {
        final delaySeconds = 2 * state.retryCount;
        debugPrint('⏳ Retrying in $delaySeconds seconds...');
        await Future.delayed(Duration(seconds: delaySeconds));
        if (mounted) fetchOffersAndCheckStatus();
      }
    } catch (e) {
      debugPrint('❌ Purchase Error (General): $e');

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load plans: ${e.toString()}',
        );
      }

      if (state.retryCount < 3) {
        final delaySeconds = 2 * state.retryCount;
        debugPrint('⏳ Retrying in $delaySeconds seconds...');
        await Future.delayed(Duration(seconds: delaySeconds));
        if (mounted) fetchOffersAndCheckStatus();
      }
    } finally {
      if (mounted && state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void _updateStatus(CustomerInfo info) {
    final isPro = info.entitlements.active.isNotEmpty;
    if (mounted) state = state.copyWith(isPro: isPro);
    AdManager.isPremium = isPro;
    AdService.isPremium = isPro;
    debugPrint('👤 Subscription updated: isPro=$isPro');
  }

  void selectPackage(Package package) {
    state = state.copyWith(selectedPackage: package);
    debugPrint('📌 Package selected: ${package.identifier}');
  }

  Future<bool> purchase(Package? package) async {
    final toPurchase = package ?? state.selectedPackage;

    // ── Mock mode ──────────────────────────────────────────────────────────
    if (PurchaseService.isMockMode) {
      debugPrint('🛒 Mock Mode: Simulating successful purchase');
      if (mounted) state = state.copyWith(isPro: true);
      AdManager.isPremium = true;
      AdService.isPremium = true;
      return true;
    }

    if (toPurchase == null) {
      debugPrint('❌ No package selected for purchase');
      return false;
    }

    try {
      if (mounted) state = state.copyWith(isLoading: true);
      await _ensureConfigured();

      debugPrint('🛒 Starting purchase: ${toPurchase.identifier}');
      final result = await Purchases.purchasePackage(toPurchase);

      if (result.customerInfo.entitlements.active.isNotEmpty) {
        debugPrint('✅ Purchase successful!');
        _updateStatus(result.customerInfo);
        return true;
      } else {
        debugPrint('⚠️ Purchase completed but no active entitlements');
        return false;
      }
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('❌ Purchase error: $code - ${e.message}');
      if (mounted) state = state.copyWith(errorMessage: _getErrorMessage(code));
      return false;
    } catch (e) {
      debugPrint('❌ Purchase error (general): $e');
      return false;
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> restore() async {
    // ── Mock mode ──────────────────────────────────────────────────────────
    if (PurchaseService.isMockMode) {
      if (mounted) state = state.copyWith(isPro: true);
      AdManager.isPremium = true;
      AdService.isPremium = true;
      return;
    }

    try {
      if (mounted) state = state.copyWith(isLoading: true);
      await _ensureConfigured();

      debugPrint('🔄 Restoring purchases...');
      final info = await Purchases.restorePurchases();
      _updateStatus(info);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('❌ Restore error: $code - ${e.message}');
      if (mounted) {
        state = state.copyWith(
            errorMessage: 'Restore failed: ${_getErrorMessage(code)}');
      }
    } catch (e) {
      debugPrint('❌ Restore error (general): $e');
      if (mounted) {
        state = state.copyWith(errorMessage: 'Restore failed: $e');
      }
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _shouldRetry(PurchasesErrorCode errorCode) {
    return errorCode == PurchasesErrorCode.networkError ||
        errorCode == PurchasesErrorCode.unknownError ||
        errorCode == PurchasesErrorCode.configurationError;
  }

  String _getErrorMessage(PurchasesErrorCode errorCode) {
    switch (errorCode) {
      case PurchasesErrorCode.networkError:
        return 'Network error. Please check your connection.';
      case PurchasesErrorCode.configurationError:
        return 'Configuration error. Please try again later.';
      case PurchasesErrorCode.unknownError:
        return 'Unknown error. Please try again.';
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Purchase cancelled.';
      default:
        return errorCode.toString();
    }
  }

  bool _isSubscriptionPackage(Package package) {
    final id = package.identifier.toLowerCase();
    final title = package.storeProduct.title.toLowerCase();
    final desc = package.storeProduct.description.toLowerCase();

    const exclude = ['coin', 'credit', 'token', 'point', 'pack', 'bundle', 'tip'];
    if (exclude.any((k) => id.contains(k) || title.contains(k) || desc.contains(k))) {
      return false;
    }

    return package.packageType == PackageType.monthly ||
        package.packageType == PackageType.annual ||
        package.packageType == PackageType.sixMonth ||
        package.packageType == PackageType.threeMonth ||
        package.packageType == PackageType.weekly ||
        ['month', 'year', 'annual', 'week', 'subscription', 'pro', 'premium']
            .any((k) => id.contains(k) || title.contains(k));
  }

  bool _isYearly(Package package) {
    final id = package.identifier.toLowerCase();
    final title = package.storeProduct.title.toLowerCase();
    return package.packageType == PackageType.annual ||
        id.contains('year') ||
        id.contains('annual') ||
        title.contains('year') ||
        title.contains('annual');
  }
}