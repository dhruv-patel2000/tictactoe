import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'package:tic_tac_toe/utils/local_storage.dart';
import 'package:tic_tac_toe/core/constants/ad_config.dart';
import 'package:tic_tac_toe/core/app.dart';
import 'package:tic_tac_toe/core/services/sound_service.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// App entry point: locks orientation/UI chrome, brings up local storage and
// sound, then Firebase and ads, before finally booting the widget tree.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.screenBackgroundGradient.last,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  // Storage/sound must be ready before the widget tree starts reading them.
  await LocalStorage.init();
  await SoundService.init();

  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    providerAndroid:
        kDebugMode ? AndroidDebugProvider() : AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? AppleDebugProvider() : AppleAppAttestProvider(),
  );

  if (AdConfig.bannerAdEnabled ||
      AdConfig.interstitialAdEnabled ||
      AdConfig.rewardedAdEnabled) {
    // Required before loading personalized/IDFA-based ads on iOS 14.5+; a
    // no-op on Android.
    await AppTrackingTransparency.requestTrackingAuthorization();

    // Every ad call site picks its network from [AdConfig.adProvider], so only
    // that one SDK is ever used. Initialising the other just costs startup
    // time and starts a second ad stack the app never talks to.
    if (AdConfig.adProvider == AdProviderType.google) {
      await MobileAds.instance.initialize();
    } else {
      await UnityAds.init(
        gameId: AdConfig.unityGameId,
        testMode: kDebugMode,
        onComplete: () => debugPrint('Unity Ads initialized'),
        onFailed: (error, message) =>
            debugPrint('Unity Ads init failed: $error $message'),
      );
    }
  }

  runApp(const App());
}
