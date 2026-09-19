import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  int _downloadCounter = 0;

  // Getter to check if ad exists from the UI
  InterstitialAd? get interstitialAd => _interstitialAd;
  int get downloadCounter => _downloadCounter;

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      loadInterstitial();
    } catch (e) {
      debugPrint('AdMob initialization failed: $e');
    }
  }

  void loadInterstitial() {
    InterstitialAd.load(
      // REPLACE WITH YOUR NEW INTERSTITIAL AD UNIT ID
      adUnitId: 'ca-app-pub-7716592682174884/6329584752',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint("Interstitial Ad Loaded Successfully");

          // Optional: Set a full-screen content callback to reload when dismissed
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  loadInterstitial(); // Automatically load the next one
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  loadInterstitial();
                },
              );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          debugPrint("Interstitial failed to load: $error");
        },
      ),
    );
  }

  // Method to increment count
  void incrementDownloadCount() {
    _downloadCounter++;
  }

  // Method to reset count after showing ad
  void resetDownloadCount() {
    _downloadCounter = 0;
  }

  // Set the reference to null so we don't try to show it again
  void clearInterstitial() {
    _interstitialAd = null;
  }

  // --- BANNER LOGIC ---
  BannerAd createBanner(Function(Ad) onLoaded) {
    return BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-7716592682174884/5230682548',
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner Ad failed: $error');
        },
      ),
    )..load();
  }

  // --- NATIVE LOGIC ---
  NativeAd createNativeAd({
    required void Function(NativeAd ad) onLoaded,
    required void Function(LoadAdError error) onFailed,
  }) {
    final ad = NativeAd(
      adUnitId: 'ca-app-pub-7716592682174884/2297587701',
      factoryId: 'songListNative', // whatever you registered
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => onLoaded(ad as NativeAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    )..load();
    return ad;
  }
}
