package com.tarurinfotech.reducer

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class NativeAdFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {

        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_medium, null) as NativeAdView

        // ── Headline (always present) ────────────────────────────────────────
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        // ── App Icon ─────────────────────────────────────────────────────────
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val icon = nativeAd.icon
        if (icon != null) {
            iconView.setImageDrawable(icon.drawable)
            iconView.visibility = View.VISIBLE
        } else {
            iconView.visibility = View.GONE
        }
        adView.iconView = iconView

        // ── Advertiser ───────────────────────────────────────────────────────
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        if (!nativeAd.advertiser.isNullOrEmpty()) {
            advertiserView.text = nativeAd.advertiser
            advertiserView.visibility = View.VISIBLE
        } else {
            advertiserView.visibility = View.GONE
        }
        adView.advertiserView = advertiserView

        // ── Star Rating ──────────────────────────────────────────────────────
        val ratingBar = adView.findViewById<RatingBar>(R.id.ad_stars)
        val starRating = nativeAd.starRating
        if (starRating != null && starRating > 0) {
            ratingBar.rating = starRating.toFloat()
            ratingBar.visibility = View.VISIBLE
        } else {
            ratingBar.visibility = View.GONE
        }
        adView.starRatingView = ratingBar

        // ── Media View ───────────────────────────────────────────────────────
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        adView.mediaView = mediaView

        // ── Body ─────────────────────────────────────────────────────────────
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        if (!nativeAd.body.isNullOrEmpty()) {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
        } else {
            bodyView.visibility = View.GONE
        }
        adView.bodyView = bodyView

        // ── Call to Action ───────────────────────────────────────────────────
        val ctaButton = adView.findViewById<Button>(R.id.ad_call_to_action)
        if (!nativeAd.callToAction.isNullOrEmpty()) {
            ctaButton.text = nativeAd.callToAction
            ctaButton.visibility = View.VISIBLE
        } else {
            ctaButton.visibility = View.GONE
        }
        adView.callToActionView = ctaButton

        // REQUIRED: bind the NativeAd to NativeAdView for click/impression tracking
        adView.setNativeAd(nativeAd)

        return adView
    }
}