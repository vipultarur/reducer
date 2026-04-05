import 'dart:io';
import 'package:flutter/foundation.dart';

// ── Ad Unit IDs ─────────────────────────────────────────────────────────────
// FIX: Always use TEST IDs in debug mode — production IDs return "No fill" (error 3)
// in development/test environments. Real ads only serve in production builds.

class AdIds {
  // ── Test Ad Unit IDs (Google official test IDs) ───────────────────────────
  static const String _testBanner        = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial  = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testAppOpen       = 'ca-app-pub-3940256099942544/9257395921';
  static const String _testNative        = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testRewarded      = 'ca-app-pub-3940256099942544/5224354917';

  // ── Android production ad unit IDs ────────────────────────────────────────
  static const String _androidBanner       = 'ca-app-pub-9155918242947466/4133195707';
  static const String _androidInterstitial = 'ca-app-pub-9155918242947466/9249791016';
  static const String _androidAppOpen      = 'ca-app-pub-9155918242947466/8096491449';
  static const String _androidNative       = 'ca-app-pub-9155918242947466/2346295726';
  static const String _androidRewarded     = 'ca-app-pub-9155918242947466/1743660491';

  // ── iOS production ad unit IDs ────────────────────────────────────────────
  static const String _iosBanner           = 'ca-app-pub-9155918242947466/4133195707';
  static const String _iosInterstitial     = 'ca-app-pub-9155918242947466/9249791016';
  static const String _iosAppOpen          = 'ca-app-pub-9155918242947466/8096491449';
  static const String _iosNative           = 'ca-app-pub-9155918242947466/2346295726';
  static const String _iosRewarded         = 'ca-app-pub-9155918242947466/1743660491';

  // ── Platform-resolved getters ─────────────────────────────────────────────
  // KEY FIX: kDebugMode → use test IDs, kReleaseMode → use production IDs
  static String get bannerId {
    if (kDebugMode) return _testBanner;
    return Platform.isAndroid ? _androidBanner : _iosBanner;
  }

  static String get interstitialId {
    if (kDebugMode) return _testInterstitial;
    return Platform.isAndroid ? _androidInterstitial : _iosInterstitial;
  }

  static String get appOpenId {
    if (kDebugMode) return _testAppOpen;
    return Platform.isAndroid ? _androidAppOpen : _iosAppOpen;
  }

  static String get nativeId {
    if (kDebugMode) return _testNative;
    return Platform.isAndroid ? _androidNative : _iosNative;
  }

  static String get rewardedId {
    if (kDebugMode) return _testRewarded;
    return Platform.isAndroid ? _androidRewarded : _iosRewarded;
  }
}
