import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';
import 'consent_manager.dart';
import 'package:reducer/core/services/remote_config_service.dart';

/// Manages all Google Mobile Ads loading, presentation, and lifecycle.
///
/// Refactored for 2026 Production Standards:
/// • Consent-aware initialization (GDPR/UMP).
/// • Robust App Open (Splash) lifecycle.
/// • Integrated error handling and fallbacks.
class AdManager {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // ── Premium flag ──────────────────────────────────────────────────────────
  /// Private premium status to prevent external tampering.
  static bool _isPremium = false;
  
  /// Public getter to check status.
  static bool get isPremium => _isPremium;

  /// Internal update method for authorized use only (PurchaseNotifier).
  static void updatePremiumStatus(bool pro) {
    _isPremium = pro;
    debugPrint('[AdManager] Global premium status synced: $pro');
  }

  // ── Ad-unit ID getters (used by widgets) ──────────────────────────────────
  static String get bannerAdUnitId => AdIds.bannerId;
  static String get nativeAdUnitId => AdIds.nativeId;

  // ── SDK Initializer ───────────────────────────────────────────────────────
  /// Initializes the SDK AFTER consent check. Returns [true] if ads can be requested.
  static Future<bool> initialize() async {
    // 1. Parallelize consent gathering and basic SDK warmup
    try {
      await ConsentManager().gatherConsent();
      
      final canRequest = await ConsentManager().canRequestAds();
      if (!canRequest || !RemoteConfigService().adsEnabled) return false;

      await MobileAds.instance.initialize();

      // 4. Preload ads in background (non-blocking)
      if (!_isPremium) {
        AdManager()._scheduleLoadEssential();
      }
      return true;
    } catch (e) {
      debugPrint('[AdManager] Initialization failed: $e');
      return false;
    }
  }

  void _scheduleLoadEssential() {
    // Only load the App Open ad immediately as it is needed for the splash screen.
    // Stagger others to reduce CPU/Network burst during startup.
    unawaited(loadAppOpenAd());

    Future.delayed(const Duration(seconds: 2), () {
      if (!_isPremium) {
        loadInterstitialAd();
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (!_isPremium) {
        getCachedBanner(); // Preload banner later
        getCachedNative(); // Preload native later
      }
    });
  }

  // ── Interstitial state ────────────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  bool _isShowing = false;
  DateTime? _lastInterstitialShownAt;
  Duration get _interstitialMinGap => Duration(seconds: RemoteConfigService().interstitialGapSeconds);

  bool get isInterstitialReady => _interstitialAd != null && !_isShowing;

  int _interstitialRetryCount = 0;
  Timer? _interstitialRetryTimer;

  void loadInterstitialAd() {
    if (isPremium || _isInterstitialLoading || _interstitialAd != null || !RemoteConfigService().adsEnabled) return;

    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
    _isInterstitialLoading = true;
    debugPrint('[AdManager] Loading Interstitial (Attempt ${_interstitialRetryCount + 1})...');

    InterstitialAd.load(
      adUnitId: AdIds.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialRetryCount = 0; // Reset on success
          debugPrint('[AdManager] ✅ Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          _interstitialRetryCount++;
          debugPrint('[AdManager] ❌ Interstitial failed: $error');
          
          // Exponential backoff: using config base and max
          final base = RemoteConfigService().retryBaseSeconds;
          final max = RemoteConfigService().retryMaxSeconds;
          final delaySeconds = (base * (1 << (_interstitialRetryCount - 1))).clamp(base, max);
          debugPrint('[AdManager] Retrying Interstitial in $delaySeconds seconds');
          _interstitialRetryTimer = Timer(Duration(seconds: delaySeconds), loadInterstitialAd);
        },
      ),
    );
  }

  /// Shows an interstitial and executes [onComplete] only AFTER dismissal or error.
  Future<void> showInterstitialAd({required VoidCallback onComplete}) async {
    if (_lastInterstitialShownAt != null &&
        DateTime.now().difference(_lastInterstitialShownAt!) <
            _interstitialMinGap) {
      onComplete();
      return;
    }
    if (isPremium || !isInterstitialReady) {
      onComplete();
      if (!isPremium && !isInterstitialReady) loadInterstitialAd();
      return;
    }

    _isShowing = true;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isShowing = false;
        loadInterstitialAd(); // Preload next
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isShowing = false;
        loadInterstitialAd();
        onComplete();
      },
    );

    await _interstitialAd!.show();
    _lastInterstitialShownAt = DateTime.now();
  }

  // ── App Open / Splash state ───────────────────────────────────────────────
  AppOpenAd? _appOpenAd;
  bool _isAppOpenLoading = false;
  DateTime? _appOpenLoadTime;
  DateTime? _lastAppOpenShownAt;
  Duration get _appOpenMinGap => Duration(seconds: RemoteConfigService().appOpenGapSeconds);

  bool get isAppOpenReady {
    if (isPremium || _appOpenAd == null || _appOpenLoadTime == null) {
      return false;
    }
    // Expire preloaded ad after 4 hours
    return DateTime.now().difference(_appOpenLoadTime!) <
        const Duration(hours: 4);
  }

  int _appOpenRetryCount = 0;
  Timer? _appOpenRetryTimer;

  Future<void> loadAppOpenAd() async {
    if (isPremium || _isAppOpenLoading || _appOpenAd != null || !RemoteConfigService().adsEnabled) return;

    _appOpenRetryTimer?.cancel();
    _appOpenRetryTimer = null;
    _isAppOpenLoading = true;
    debugPrint('[AdManager] Loading App Open (Attempt ${_appOpenRetryCount + 1})...');

    await AppOpenAd.load(
      adUnitId: AdIds.appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
          _appOpenLoadTime = DateTime.now();
          _appOpenRetryCount = 0; // Reset on success
          debugPrint('[AdManager] ✅ App Open loaded');
        },
        onAdFailedToLoad: (error) {
          _isAppOpenLoading = false;
          _appOpenAd = null;
          _appOpenRetryCount++;
          debugPrint('[AdManager] ❌ App Open failed: $error');

          // Exponential backoff
          final base = RemoteConfigService().retryBaseSeconds;
          final max = RemoteConfigService().retryMaxSeconds;
          final delaySeconds = (base * (1 << (_appOpenRetryCount - 1))).clamp(base, max);
          debugPrint('[AdManager] Retrying App Open in $delaySeconds seconds');
          _appOpenRetryTimer = Timer(Duration(seconds: delaySeconds), loadAppOpenAd);
        },
      ),
    );
  }

  /// Specialized show for Splash screen. Executes [onDone] after dismissal.
  Future<void> showSplashAd({required VoidCallback onDone}) async {
    if (isPremium) {
      onDone();
      return;
    }

    // Special case for splash: we might want to be more lenient with the gap
    // or just let the Remote Config handle it.
    if (_lastAppOpenShownAt != null &&
        DateTime.now().difference(_lastAppOpenShownAt!) < _appOpenMinGap) {
      debugPrint('[AdManager] App Open gap not met, skipping splash ad');
      onDone();
      return;
    }

    if (isAppOpenReady) {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _appOpenAd = null;
          _lastAppOpenShownAt = DateTime.now();
          onDone();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _appOpenAd = null;
          onDone();
        },
      );
      await _appOpenAd!.show();
    } else {
      // If not ready, load and wait max 5 seconds (Splash optimization)
      if (!_isAppOpenLoading) {
        unawaited(loadAppOpenAd());
      }

      int timerCount = 0;
      // Increased timeout to 5 seconds (100 * 50ms) for better load chance on splash
      while (_isAppOpenLoading && timerCount < 100) {
        await Future.delayed(const Duration(milliseconds: 50));
        timerCount++;
      }

      if (isAppOpenReady) {
        await showSplashAd(onDone: onDone);
      } else {
        debugPrint('[AdManager] App Open timeout (5s), skipping splash ad');
        onDone();
      }
    }
  }

  BannerAd? _cachedBannerAd;
  bool _isBannerLoading = false;
  int _bannerRetryCount = 0;
  Timer? _bannerRetryTimer;

  NativeAd? _cachedNativeAd;
  bool _isNativeLoading = false;
  int _nativeRetryCount = 0;
  Timer? _nativeRetryTimer;

  /// Retrieves the persistent banner ad or initiates a load.
  BannerAd? getCachedBanner() {
    if (isPremium) return null;
    if (_cachedBannerAd == null && !_isBannerLoading && _bannerRetryTimer == null) {
      _loadPersistentBanner();
    }
    return _cachedBannerAd;
  }

  /// Retrieves the persistent native ad or initiates a load.
  NativeAd? getCachedNative() {
    if (isPremium) return null;
    if (_cachedNativeAd == null && !_isNativeLoading && _nativeRetryTimer == null) {
      _loadPersistentNative();
    }
    return _cachedNativeAd;
  }

  void _loadPersistentBanner() {
    if (_isBannerLoading || _cachedBannerAd != null || !RemoteConfigService().adsEnabled) return;
    
    _bannerRetryTimer?.cancel();
    _bannerRetryTimer = null;
    _isBannerLoading = true;
    
    BannerAd(
      adUnitId: AdIds.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _cachedBannerAd = ad as BannerAd;
          _isBannerLoading = false;
          _bannerRetryCount = 0;
          debugPrint('[AdManager] ✅ Global Banner Loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isBannerLoading = false;
          _cachedBannerAd = null;
          _bannerRetryCount++;
          
          // Exponential backoff
          final base = 10; // Lowered from 30 to 10 for better response
          final max = 300; // Capped at 5 minutes for persistent ads
          final delaySeconds = (base * (1 << (_bannerRetryCount - 1))).clamp(base, max);
          
          debugPrint('[AdManager] ❌ Banner Failed: $error. Retrying in $delaySeconds seconds (Attempt $_bannerRetryCount)');
          _bannerRetryTimer = Timer(Duration(seconds: delaySeconds), _loadPersistentBanner);
        },
      ),
    ).load();
  }

  void _loadPersistentNative() {
    if (_isNativeLoading || _cachedNativeAd != null || !RemoteConfigService().adsEnabled) return;
    
    _nativeRetryTimer?.cancel();
    _nativeRetryTimer = null;
    _isNativeLoading = true;
    
    NativeAd(
      adUnitId: AdIds.nativeId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: isPremium ? Colors.transparent : (WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white),
        cornerRadius: 12.0,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _cachedNativeAd = ad as NativeAd;
          _isNativeLoading = false;
          _nativeRetryCount = 0;
          debugPrint('[AdManager] ✅ Global Native Ad Loaded');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isNativeLoading = false;
          _cachedNativeAd = null;
          _nativeRetryCount++;
          
          // Exponential backoff
          final base = 10; // Lowered from 30 to 10
          final max = 300; // Capped at 5 minutes
          final delaySeconds = (base * (1 << (_nativeRetryCount - 1))).clamp(base, max);
          
          debugPrint('[AdManager] ❌ Native Failed: $error. Retrying in $delaySeconds seconds (Attempt $_nativeRetryCount)');
          _nativeRetryTimer = Timer(Duration(seconds: delaySeconds), _loadPersistentNative);
        },
      ),
    ).load();
  }

  // Tracking which ads are currently held by a widget to prevent "Already in tree" errors.
  final Set<int> _activeAdHashes = {};

  bool isAdAvailable(Ad ad) {
    return !_activeAdHashes.contains(ad.hashCode);
  }

  void claimAd(Ad ad) {
    _activeAdHashes.add(ad.hashCode);
  }

  void releaseAd(Ad ad) {
    _activeAdHashes.remove(ad.hashCode);
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  void disposeAll() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    
    _appOpenAd?.dispose();
    _appOpenAd = null;

    _cachedBannerAd?.dispose();
    _cachedBannerAd = null;

    _cachedNativeAd?.dispose();
    _cachedNativeAd = null;

    _bannerRetryTimer?.cancel();
    _bannerRetryTimer = null;
    _nativeRetryTimer?.cancel();
    _nativeRetryTimer = null;
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
    _appOpenRetryTimer?.cancel();
    _appOpenRetryTimer = null;

    _activeAdHashes.clear();
    _isShowing = false;
  }
}

// ── App Resume Lifecycle Observer ────────────────────────────────────────────
class AppLifecycleObserver extends WidgetsBindingObserver {
  AppLifecycleState? _lastState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lastState == state) return;
    _lastState = state;

    if (state == AppLifecycleState.resumed) {
      debugPrint('[Lifecycle] App resumed, showing App Open ad if ready');
      AdManager().showSplashAd(onDone: () {
        debugPrint('[Lifecycle] App Open ad completed or skipped');
      });
    }
  }
}

