import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Keep these imports: DbKey (bottom of file) needs dbPartA-dbPartD from one of them.
import 'package:mezgebe_sibhat/features/songs/data/models/server_model.dart';
import 'package:mezgebe_sibhat/features/songs/domain/repository/song_repo.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/change_theme_usecase.dart';
import 'package:mezgebe_sibhat/features/songs/domain/usecases/submit_feedback_usecase.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Set to true ONLY while testing the GDPR form. Must be false for release.
  static const bool _testGdpr = false;
  // Put your device hash here (it is printed in logcat when you run the app).
  static const List<String> _testDeviceIds = [
    '7D6142C42749C893F341BA6CAE3D7DA5',
  ];

  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  DateTime? _appOpenAdLoadTime;
  bool _isShowingAppOpenAd = false;

  bool _isShowingConsentForm = false;
  bool _adsInitialized = false;
  bool _initStarted = false;

  /// UI can listen to this to build banner/native ads only when ready.
  final ValueNotifier<bool> adsReady = ValueNotifier<bool>(false);

  AppOpenAd? get appOpenAd => _appOpenAd;
  bool get isShowingConsentForm => _isShowingConsentForm;
  bool get adsInitialized => _adsInitialized;

  int _downloadCounter = 0;

  InterstitialAd? get interstitialAd => _interstitialAd;
  int get downloadCounter => _downloadCounter;

  // ---------------------------------------------------------------------------
  // INIT + GDPR CONSENT (UMP)
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    if (_initStarted) return;
    _initStarted = true;

    final completer = Completer<void>();
    _isShowingConsentForm = true;

    if (_testGdpr) {
      await ConsentInformation.instance.reset();
    }

    final params = _testGdpr
        ? ConsentRequestParameters(
            consentDebugSettings: ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: _testDeviceIds,
            ),
          )
        : ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      // Success
      () async {
        try {
          final status = await ConsentInformation.instance.getConsentStatus();
          final formAvailable = await ConsentInformation.instance
              .isConsentFormAvailable();
          debugPrint('UMP status: $status | form available: $formAvailable');

          await ConsentForm.loadAndShowConsentFormIfRequired((
            FormError? error,
          ) async {
            if (error != null) {
              debugPrint(
                'Consent form error: ${error.errorCode} ${error.message}',
              );
            }
            final after = await ConsentInformation.instance.getConsentStatus();
            debugPrint('UMP status after form: $after');
            _isShowingConsentForm = false;
            await _initAdsIfAllowed();
            if (!completer.isCompleted) completer.complete();
          });
        } catch (e) {
          debugPrint('Consent form failed: $e');
          _isShowingConsentForm = false;
          await _initAdsIfAllowed();
          if (!completer.isCompleted) completer.complete();
        }
      },
      // Failure
      (FormError error) async {
        debugPrint(
          'Consent info update failed: ${error.errorCode} ${error.message}',
        );
        _isShowingConsentForm = false;
        await _initAdsIfAllowed();
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  Future<void> _initAdsIfAllowed() async {
    if (_adsInitialized) return;

    try {
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        _adsInitialized = true;

        loadInterstitial();
        loadAppOpenAd();

        adsReady.value = true;
        debugPrint('AdMob initialized successfully.');
      } else {
        debugPrint('Consent not available for requesting ads.');
      }
    } catch (e) {
      debugPrint('AdMob initialization failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVACY OPTIONS (required by Google for EEA/UK users)
  // ---------------------------------------------------------------------------
  Future<bool> isPrivacyOptionsRequired() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('Privacy options check failed: $e');
      return false;
    }
  }

  void showPrivacyOptionsForm() {
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        debugPrint(
          'Privacy options error: ${error.errorCode} ${error.message}',
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // INTERSTITIAL
  // ---------------------------------------------------------------------------
  void loadInterstitial() {
    if (!_adsInitialized) return;

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-7716592682174884/6329584752',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('Interstitial Ad Loaded Successfully');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  void incrementDownloadCount() {
    _downloadCounter++;
  }

  void resetDownloadCount() {
    _downloadCounter = 0;
  }

  void clearInterstitial() {
    _interstitialAd = null;
  }

  // ---------------------------------------------------------------------------
  // BANNER (returns null until consent flow is done and ads are initialized)
  // ---------------------------------------------------------------------------
  BannerAd? createBanner(Function(Ad) onLoaded) {
    if (!_adsInitialized) return null;

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

  // ---------------------------------------------------------------------------
  // NATIVE (returns null until consent flow is done and ads are initialized)
  // ---------------------------------------------------------------------------
  NativeAd? createNativeAd({
    required void Function(NativeAd ad) onLoaded,
    required void Function(LoadAdError error) onFailed,
  }) {
    if (!_adsInitialized) return null;

    return NativeAd(
      adUnitId: 'ca-app-pub-7716592682174884/2297587701',
      factoryId: 'songListNative',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => onLoaded(ad as NativeAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    )..load();
  }

  // ---------------------------------------------------------------------------
  // APP OPEN
  // ---------------------------------------------------------------------------
  void loadAppOpenAd() {
    if (!_adsInitialized) return;
    if (_appOpenAd != null) return;

    AppOpenAd.load(
      adUnitId: 'ca-app-pub-7716592682174884/7031316272',
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenAdLoadTime = DateTime.now();
          debugPrint('App Open Ad Loaded Successfully');
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _appOpenAdLoadTime = null;
          debugPrint('App Open Ad failed to load: $error');
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    // Never show while the consent form is up or before ads are initialized.
    if (_isShowingConsentForm || !_adsInitialized) return;
    if (_isShowingAppOpenAd) return;

    final ad = _appOpenAd;
    if (ad == null) {
      debugPrint('App Open Ad is not ready yet.');
      loadAppOpenAd();
      return;
    }

    // App Open ads expire after 4 hours.
    if (_appOpenAdLoadTime == null ||
        DateTime.now().difference(_appOpenAdLoadTime!) >
            const Duration(hours: 4)) {
      debugPrint('App Open Ad expired. Loading a new one.');
      ad.dispose();
      _appOpenAd = null;
      _appOpenAdLoadTime = null;
      loadAppOpenAd();
      return;
    }

    _isShowingAppOpenAd = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('App Open Ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('App Open Ad dismissed');
        ad.dispose();
        _appOpenAd = null;
        _appOpenAdLoadTime = null;
        _isShowingAppOpenAd = false;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App Open Ad failed to show: $error');
        ad.dispose();
        _appOpenAd = null;
        _appOpenAdLoadTime = null;
        _isShowingAppOpenAd = false;
        loadAppOpenAd();
      },
    );

    ad.show();
  }
}

class DbKey {
  static String get value {
    return dbPartC + dbPartA + dbPartB + dbPartD;
  }
}
