import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/features/premium/premium.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/core/ads/consent_manager.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  int _retryAttempt = 0;
  Timer? _loadDebounce;

  @override
  void initState() {
    super.initState();
    // Fix: Delay platform-view creation to avoid first-frame jank.
    _loadDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadAd();
    });
  }

  @override
  void dispose() {
    _loadDebounce?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    // Don't load if premium user
    if (AdManager.isPremium) return;
    // Don't load if already loading or loaded
    if (_isLoading || _isAdLoaded) return;

    // 2026 GDPR Check: Only load if consent has been granted/not required
    final canRequest = await ConsentManager().canRequestAds();
    if (!canRequest) {
      debugPrint('[BannerAd] Skipping load: Consent not granted.');
      return;
    }

    setState(() => _isLoading = true);

    // FIX: AdManager.bannerAdUnitId now returns TEST ID in debug mode
    final ad = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          debugPrint('[BannerAd] ✅ Loaded successfully');
          setState(() {
            _bannerAd = ad as BannerAd;
            _isAdLoaded = true;
            _isLoading = false;
            _retryAttempt = 0; // Reset on success
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;

          debugPrint('[BannerAd] ❌ Failed: $error');
          setState(() {
            _bannerAd = null;
            _isAdLoaded = false;
            _isLoading = false;
          });

          _scheduleRetry();
        },
        onAdOpened: (ad) => debugPrint('[BannerAd] Opened'),
        onAdClosed: (ad) => debugPrint('[BannerAd] Closed'),
      ),
    );

    await ad.load();
  }


  void _scheduleRetry() {
    _retryAttempt++;
    final delaySeconds = (_retryAttempt <= 1)
        ? 10
        : (10 * (1 << (_retryAttempt - 1))).clamp(10, 120);

    debugPrint('[BannerAd] Retry #$_retryAttempt in ${delaySeconds}s');

    Future.delayed(Duration(seconds: delaySeconds), () {
      if (mounted && !_isAdLoaded) {
        _loadAd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Check premium via provider too (live updates when user upgrades)
    final isPro = ref.watch(premiumControllerProvider).isPro;
    if (isPro || AdManager.isPremium) {
      return const SizedBox.shrink();
    }

    // Show nothing (no blank gap) while loading or if failed
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // Show the banner with a fixed height to avoid layout jumps
    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
