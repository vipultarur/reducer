import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/core/ads/consent_manager.dart';
import 'package:reducer/core/theme/design_tokens.dart';

enum NativeAdSize { small, medium }

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({
    super.key,
    this.size = NativeAdSize.small,
  });

  final NativeAdSize size;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  static const int _maxRetries = 3;
  static const double _smallHeight = 100;
  static const double _mediumHeight = 320;

  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  int _retryCount = 0;
  Timer? _loadDebounce;

  @override
  void initState() {
    super.initState();
    // Fix: lazy load avoids creating multiple platform views during first frame.
    _loadDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _loadNativeAd();
    });
  }

  Future<void> _loadNativeAd() async {
    if (_isLoading || AdManager.isPremium) return;
    _isLoading = true;

    final canRequestAds = await ConsentManager().canRequestAds();
    if (!canRequestAds) {
      _isLoading = false;
      debugPrint('[NativeAd] Skip load: consent not ready.');
      return;
    }

    _nativeAd?.dispose();

    final style = NativeTemplateStyle(
      templateType: widget.size == NativeAdSize.small
          ? TemplateType.small
          : TemplateType.medium,
      mainBackgroundColor: Colors.transparent,
      cornerRadius: 12,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: DesignTokens.primaryBlue,
        style: NativeTemplateFontStyle.bold,
        size: 14,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.black87,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.bold,
        size: 14,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.black54,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 12,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.black45,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 11,
      ),
    );

    final ad = NativeAd(
      adUnitId: AdManager.nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: style,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _retryCount = 0;
          });
          _isLoading = false;
          debugPrint('[NativeAd] Loaded (${widget.size.name})');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isLoading = false;
          if (!mounted) return;
          setState(() {
            _nativeAd = null;
            _isLoaded = false;
          });
          debugPrint('[NativeAd] Failed: $error');
          _scheduleRetry();
        },
      ),
    );

    _nativeAd = ad;
    ad.load();
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) return;
    _retryCount += 1;
    final delay = Duration(seconds: 15 * _retryCount);
    Future.delayed(delay, () {
      if (mounted && !_isLoaded) {
        _loadNativeAd();
      }
    });
  }

  @override
  void dispose() {
    _loadDebounce?.cancel();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AdManager.isPremium) return const SizedBox.shrink();

    final height =
        widget.size == NativeAdSize.small ? _smallHeight : _mediumHeight;

    if (!_isLoaded || _nativeAd == null) {
      return Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(child: AdWidget(ad: _nativeAd!)),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Ad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
