package com.tarurinfotech.reducer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the native ad factory with ID "introNativeAd".
        // This ID must exactly match the `factoryId` in NativeAdService.dart.
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "introNativeAd",
            NativeAdFactory(applicationContext)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "introNativeAd")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}