import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _claimedAd;

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
    final ad = AdManager().getCachedBanner();
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
    if (isPro || AdManager.isPremium) {
      return const SizedBox.shrink();
    }

    if (_claimedAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: _claimedAd!.size.height.toDouble(),
      child: AdWidget(ad: _claimedAd!),
    );
  }
}
