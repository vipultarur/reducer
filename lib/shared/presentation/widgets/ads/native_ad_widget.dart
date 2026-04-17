import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';

enum NativeAdSize { small, medium }

class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({
    super.key,
    this.size = NativeAdSize.small,
  });

  final NativeAdSize size;

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _claimedAd;

  @override
  void initState() {
    super.initState();
    _tryClaimAd();
  }

  @override
  void dispose() {
    if (_claimedAd != null) {
      AdManager().releaseAd(_claimedAd!);
    }
    super.dispose();
  }

  void _tryClaimAd() {
    final ad = AdManager().getCachedNative();
    if (ad != null && AdManager().isAdAvailable(ad)) {
      AdManager().claimAd(ad);
      setState(() {
        _claimedAd = ad;
      });
    } else {
      // If busy or not loaded, retry shortly
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _claimedAd == null) _tryClaimAd();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(premiumControllerProvider).isPro;
    if (isPro || AdManager.isPremium) return const SizedBox.shrink();

    final double height = widget.size == NativeAdSize.small ? 100 : 320;

    if (_claimedAd == null) {
      // Placeholder while waiting for the global ad instance to become available
      return Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
          Positioned.fill(child: AdWidget(ad: _claimedAd!)),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
              ),
              child: const Text(
                'Ad',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
