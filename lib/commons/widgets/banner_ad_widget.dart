import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tic_tac_toe/core/constants/ad_config.dart';
import 'package:tic_tac_toe/core/routes/route_observer.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

// Bottom banner ad slot: shows a Google adaptive banner or Unity banner
// depending on AdConfig, and reloads itself when the screen is revealed
// again since native ad views don't survive being covered.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with WidgetsBindingObserver, RouteAware {
  /// Backoff between load attempts, capped at the last entry. AdMob no-fill is
  /// common and transient, so a single failure must not retire the slot for
  /// the rest of the session.
  static const List<Duration> _retryDelays = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 45),
  ];

  // the currently loading/loaded Google banner ad instance
  BannerAd? _bannerAd;
  // adaptive banner size resolved for the current screen width
  AdSize? _adSize;
  // whether _bannerAd finished loading and is ready to display
  bool _isLoaded = false;
  // consecutive load failures; indexes into _retryDelays
  int _failureCount = 0;
  // pending retry after a failed load, if any
  Timer? _retryTimer;
  // route this widget registered with appRouteObserver, for didPopNext
  PageRoute<dynamic>? _subscribedRoute;

  /// Bumped on every (re)load so that callbacks belonging to an ad we have
  /// already thrown away cannot touch the current state.
  int _generation = 0;

  static bool get _usesGoogleBanner =>
      AdConfig.bannerAdEnabled && AdConfig.adProvider == AdProviderType.google;

  @override
  void initState() {
    super.initState();
    if (_usesGoogleBanner) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_usesGoogleBanner) return;

    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        appRouteObserver.unsubscribe(this);
        _subscribedRoute = null;
      }
      if (route is PageRoute<dynamic>) {
        _subscribedRoute = route;
        appRouteObserver.subscribe(this, route);
      }
    }

    if (_bannerAd == null && _retryTimer == null) {
      _loadGoogleBanner();
    }
  }

  /// This screen has just been revealed again by the route on top of it
  /// popping.
  ///
  /// The native view behind an [AdWidget] does not reliably survive being
  /// covered — by another screen, or by a full-screen interstitial, which
  /// pauses the whole activity — and once its surface is gone, nothing in the
  /// existing widget brings it back, leaving an empty slot for good. Loading a
  /// fresh ad also gets a fresh platform view.
  @override
  void didPopNext() => _reload();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Same reasoning as [didPopNext], for the interstitial / app-switch case.
    // Screens further down the stack are left alone; they reload when they are
    // popped back to.
    if (state == AppLifecycleState.resumed &&
        (_subscribedRoute?.isCurrent ?? true)) {
      _reload();
    }
  }

  Future<void> _reload() async {
    if (!_usesGoogleBanner || !mounted) return;

    _retryTimer?.cancel();
    _retryTimer = null;
    _failureCount = 0;

    final BannerAd? previous = _bannerAd;
    // Invalidates any in-flight load along with the ad being replaced.
    _generation++;

    if (previous != null || _isLoaded) {
      setState(() {
        _bannerAd = null;
        _isLoaded = false;
      });
      // Let the frame that took the old AdWidget out of the tree finish before
      // the native ad view behind it is torn down.
      await WidgetsBinding.instance.endOfFrame;
      previous?.dispose();
      if (!mounted) return;
    }

    await _loadGoogleBanner();
  }

  Future<void> _loadGoogleBanner() async {
    if (!mounted) return;
    final int generation =
        ++_generation; // snapshot to detect if a newer load supersedes this one

    AdSize? size = _adSize;
    if (size == null) {
      final int width = MediaQuery.sizeOf(context).width.truncate();
      size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (size == null) {
        debugPrint('[Ads] Unable to get adaptive banner size');
        return;
      }
      if (!mounted || generation != _generation) return;
      setState(() => _adSize = size);
    }

    final BannerAd banner = BannerAd(
      adUnitId: AdConfig.bannerAdID,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted || generation != _generation) {
            ad.dispose();
            return;
          }
          _failureCount = 0;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('[Ads] Banner failed to load: $error');
          ad.dispose();
          if (!mounted || generation != _generation) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
          _scheduleRetry();
        },
      ),
    );
    _bannerAd = banner;
    await banner.load();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final Duration delay =
        _retryDelays[_failureCount.clamp(0, _retryDelays.length - 1)];
    _failureCount++;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (mounted) _loadGoogleBanner();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    if (_subscribedRoute != null) appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.bannerAdEnabled) return const SizedBox.shrink();

    if (AdConfig.adProvider == AdProviderType.google) {
      final AdSize? size = _adSize;

      if (size == null) return const SizedBox.shrink();
      final BannerAd? ad = _bannerAd;
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: size.height.toDouble(),
          alignment: Alignment.center,
          child: (_isLoaded && ad != null)
              // Keyed by the ad so that replacing it builds a new platform
              // view instead of re-using the retired one's element.
              ? AdWidget(key: ObjectKey(ad), ad: ad)
              : const SizedBox.shrink(),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: UnityBannerAd(
        placementId: AdConfig.unityBannerPlacementId,
        onFailed: (placementId, error, message) =>
            debugPrint('[Ads] Unity banner failed to load: $error $message'),
      ),
    );
  }
}
