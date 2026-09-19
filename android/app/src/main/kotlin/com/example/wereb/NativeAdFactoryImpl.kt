package app.mesay.mezgebe_sibhat

import android.content.Context
import android.view.LayoutInflater
import android.widget.Button
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class NativeAdFactoryImpl(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        val ctaView = adView.findViewById<Button>(R.id.ad_call_to_action)
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)

        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = android.view.View.VISIBLE
        } else {
            bodyView.visibility = android.view.View.GONE
        }
        adView.bodyView = bodyView

        if (nativeAd.callToAction != null) {
            ctaView.text = nativeAd.callToAction
            ctaView.visibility = android.view.View.VISIBLE
        } else {
            ctaView.visibility = android.view.View.GONE
        }
        adView.callToActionView = ctaView

        if (nativeAd.advertiser != null) {
            advertiserView.text = nativeAd.advertiser
            advertiserView.visibility = android.view.View.VISIBLE
        } else {
            advertiserView.visibility = android.view.View.GONE
        }
        adView.advertiserView = advertiserView

        adView.mediaView = mediaView
        nativeAd.mediaContent?.let { mediaView.mediaContent = it }

        adView.setNativeAd(nativeAd)

        return adView
    }
}