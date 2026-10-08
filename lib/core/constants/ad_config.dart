import 'dart:io';

/// Ad-network and IAP tuning. Ported from the pre-redesign shop screen.
enum AdProviderType {
  google,
  unity,
}

// Central switchboard for ad enablement, network selection, and IAP ids.
class AdConfig {
  AdConfig._();

  static const bool bannerAdEnabled = false;
  static const bool interstitialAdEnabled = false;
  static const bool rewardedAdEnabled = false;

  /// Defines which ad network to use: Google AdMob or Unity Ads.
  static const AdProviderType adProvider = AdProviderType.google;

  /// AdMob test rewarded ad unit id — replace with a real ad unit id before release.
  static String get rewardedAdID {
    if (Platform.isAndroid) return "ca-app-pub-3940256099942544/5224354917";
    if (Platform.isIOS) return "ca-app-pub-3940256099942544/1712485313";
    return '';
  }

  /// AdMob test interstitial ad unit id — replace with a real ad unit id before release.
  static String get interstitialAdID {
    if (Platform.isAndroid) return "ca-app-pub-3940256099942544/1033173712";
    if (Platform.isIOS) return "ca-app-pub-3940256099942544/4411468910";
    return '';
  }

  /// AdMob test banner ad unit id (platform-specific) — replace with real ad
  /// unit ids before release.
  static String get bannerAdID {
    if (Platform.isAndroid) return "ca-app-pub-3940256099942544/6300978111";
    if (Platform.isIOS) return "ca-app-pub-3940256099942544/2934735716";
    return '';
  }

  /// Unity Ads test game id — replace with a real game id before release.
  static final String unityGameId = Platform.isAndroid ? '4839511' : '4839510';

  static String get unityRewardedPlacementId {
    if (Platform.isAndroid) return 'Rewarded_Android';
    if (Platform.isIOS) return 'Rewarded_iOS';
    return '';
  }

  static String get unityInterstitialPlacementId {
    if (Platform.isAndroid) return 'Interstitial_Android';
    if (Platform.isIOS) return 'Interstitial_iOS';
    return '';
  }

  static String get unityBannerPlacementId {
    if (Platform.isAndroid) return 'Banner_Android';
    if (Platform.isIOS) return 'Banner_iOS';
    return '';
  }

  /// Max rewarded-ad coin claims allowed per calendar day.
  static const int adLimit = 5;

  /// Coins credited per rewarded-ad watch.
  static const int adRewardAmount = 50;

  /// In-app product ids — must match the Play Console / App Store listings.
  static const List<String> coinProductIds = [
    '100_coins',
    '500_coins',
    '1000_coins',
    '2000_coins',
    '5000_coins',
    '10000_coins',
  ];
}
