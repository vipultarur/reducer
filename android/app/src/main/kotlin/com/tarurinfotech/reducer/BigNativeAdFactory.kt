package com.tarurinfotech.reducer

import android.view.LayoutInflater
import android.view.View
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class BigNativeAdFactory(private val layoutInflater: LayoutInflater) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.big_native_ad, null
        ) as NativeAdView

        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.iconView = adView.findViewById(R.id.ad_icon)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)

        (adView.headlineView as? android.widget.TextView)?.text = nativeAd.headline
        (adView.bodyView as? android.widget.TextView)?.text = nativeAd.body
        (adView.callToActionView as? android.widget.Button)?.text = nativeAd.callToAction

        val icon = nativeAd.icon
        if (icon != null) {
            (adView.iconView as? android.widget.ImageView)?.setImageDrawable(icon.drawable)
            adView.iconView?.visibility = View.VISIBLE
        } else {
            adView.iconView?.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}