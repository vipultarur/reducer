import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/ads/ad_ids.dart';
import 'dart:io';
import 'ad_service.dart';
import 'remote_config_service.dart';

class NativeAdService {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isLoaded;
  NativeAd? get nativeAd => _nativeAd;

  void load({
    required VoidCallback onLoaded,
    void Function(String message)? onFailed,
  }) {
    if (AdService.isPremium) return;
    if (_isLoading || _isLoaded) return;

    _isLoading = true;

    // Use Remote Config or Fallback to AdIds
    // String adUnitId = Platform.isAndroid ? AdIds.androidNative : AdIds.iosNative;
    
    // BETTER: Get from Remote Config so it's dynamic
    String adUnitId = RemoteConfigService().adConfig.introNativeAd;
    if (adUnitId.isEmpty) {
      adUnitId = Platform.isAndroid ? AdIds.androidNative : AdIds.iosNative;
    }

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'introNativeAd',
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.landscape,
        videoOptions: VideoOptions(startMuted: true),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('[NativeAdService] introNativeAd loaded.');
          _isLoaded = true;
          _isLoading = false;
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[NativeAdService] Failed: ${error.message}');
          ad.dispose();
          _nativeAd = null;
          _isLoaded = false;
          _isLoading = false;
          onFailed?.call(error.message);
        },
        onAdImpression: (_) =>
            debugPrint('[NativeAdService] Impression recorded.'),
        onAdClicked: (_) => debugPrint('[NativeAdService] Ad clicked.'),
      ),
    )..load();
  }

  void dispose() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
    _isLoading = false;
  }
}