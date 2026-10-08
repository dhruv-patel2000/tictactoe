import 'package:flutter/foundation.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'package:tic_tac_toe/core/constants/ad_config.dart';

/// Loads and immediately shows a full-screen interstitial ad, mirroring the
/// pre-redesign shop/history/leaderboard/skins/more-games screens, which
/// each fired one interstitial on open. Uses [AdConfig.adProvider] to pick
/// Google AdMob vs Unity Ads, same as the rewarded-ad flow in the shop.
class InterstitialAdService {
  InterstitialAdService._();

  static InterstitialAd?
      _interstitialAd; // cached preloaded ad, ready to show; null while none is loaded

  static void loadAd() {
    if (!AdConfig.interstitialAdEnabled) return;
    if (AdConfig.adProvider == AdProviderType.google) {
      InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdID,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            showAd();
          },
          onAdFailedToLoad: (error) =>
              debugPrint('[Ads] Interstitial failed to load: $error'),
        ),
      );
    } else {
      UnityAds.load(
        placementId: AdConfig.unityInterstitialPlacementId,
        onComplete: (placementId) => showAd(),
        onFailed: (placementId, error, message) => debugPrint(
            '[Ads] Unity interstitial failed to load: $error $message'),
      );
    }
  }

  static void showAd() {
    if (AdConfig.adProvider == AdProviderType.google) {
      final ad = _interstitialAd;
      if (ad == null) {
        loadAd();
        return;
      }
      _interstitialAd = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) => ad.dispose(),
        onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
      );
      ad.show();
    } else {
      UnityAds.showVideoAd(
        placementId: AdConfig.unityInterstitialPlacementId,
        onFailed: (placementId, error, message) => debugPrint(
            '[Ads] Unity interstitial failed to show: $error $message'),
      );
    }
  }
}
