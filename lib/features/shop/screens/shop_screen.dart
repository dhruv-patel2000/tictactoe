import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/utils/ui_utils.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/constants/ad_config.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/shop/models/shop_item_model.dart';
import 'package:tic_tac_toe/features/shop/widgets/shop_item_card.dart';

// In-app purchase screen: shows coin packs and a "watch ad" option, wires
// flutter_inapp_purchase callbacks and Google/Unity rewarded ads to coin credits.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  static Route route(RouteSettings settings) => GradientRouter(
        builder: (context) => const ShopScreen(),
      );

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  //--------------------------------------------------
  // Fields
  //--------------------------------------------------
  StreamSubscription<List<ShopItem>>? _catalogSub;
  // Credits coins once a store purchase completes.
  StreamSubscription<Purchase?>? _purchaseUpdatedSub;
  // Surfaces failed/cancelled purchase attempts.
  StreamSubscription<PurchaseError>? _purchaseErrorSub;

  /// Backoff between rewarded-ad load attempts, capped at the last entry. A
  /// no-fill is common and transient, so one failed preload must not leave the
  /// button dead for the rest of the session.
  static const List<Duration> _adRetryDelays = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 45),
  ];

  // Coin packs/ad entry loaded from Firestore; null while the initial stream event is pending.
  List<ShopItem>? _catalog;
  // Store product details (price etc.) keyed by product id, from fetchProducts.
  final Map<String, Product> _products = {};
  // Id of the shop item currently being bought; drives that card's spinner.
  String? _purchasingId;
  // Preloaded ad ready to show immediately on "watch ad" tap.
  RewardedAd? _rewardedAd;
  bool _isLoadingRewardedAd = false;

  /// Set when the button is tapped with no ad ready. The next successful load
  /// shows itself straight away instead of making the user tap again.
  bool _isWaitingForRewardedAd = false;
  // Consecutive load failures; indexes into _adRetryDelays for backoff.
  int _rewardedAdFailureCount = 0;
  // Pending scheduled retry, cancelled/replaced as attempts occur.
  Timer? _rewardedAdRetryTimer;

  //--------------------------------------------------
  // Lifecycle
  //--------------------------------------------------
  @override
  void initState() {
    super.initState();
    _catalogSub = DatabaseService.instance.streamShopItems().listen((items) {
      if (mounted) setState(() => _catalog = items);
    });
    _initIap();
    _preloadRewardedAdIfAllowed();
  }

  @override
  void dispose() {
    _catalogSub?.cancel();
    _purchaseUpdatedSub?.cancel();
    _purchaseErrorSub?.cancel();
    _rewardedAdRetryTimer?.cancel();
    _rewardedAd?.dispose();
    FlutterInappPurchase.instance.endConnection();
    super.dispose();
  }

  //--------------------------------------------------
  // In-app purchase logic
  //--------------------------------------------------
  Future<void> _initIap() async {
    try {
      await FlutterInappPurchase.instance.initConnection();
      _purchaseUpdatedSub = FlutterInappPurchase
          .instance.purchaseUpdatedListener
          .listen(_onPurchaseUpdated);
      _purchaseErrorSub =
          FlutterInappPurchase.instance.purchaseErrorListener.listen((error) {
        setState(() => _purchasingId = null);
        if (!mounted) return;
        _showSnack(context, error.message);
      });

      final products = await FlutterInappPurchase.instance
          .fetchProducts<Product>(skus: AdConfig.coinProductIds);
      if (!mounted) return;
      setState(() {
        for (final product in products) {
          _products[product.id] = product;
        }
      });
    } catch (e) {
      debugPrint('[Shop] IAP init failed: $e');
    }
  }

  int? _coinsForProductId(String productId) {
    for (final item in _catalog ?? const <ShopItem>[]) {
      if (item.id == productId) return item.coins;
    }
    return null;
  }

  Future<void> _onPurchaseUpdated(Purchase? purchase) async {
    if (purchase == null) return;
    final int? coins = _coinsForProductId(purchase.productId);
    if (coins != null) {
      final String uid = DatabaseService.instance.userId!;
      // claimPurchase guards against crediting the same purchase id twice
      // (e.g. a re-delivered purchase update after app restart).
      final bool claimed =
          await DatabaseService.instance.claimPurchase(uid, purchase.id);
      if (claimed) {
        await DatabaseService.instance.creditCoins(uid, coins);
      }
    }
    // Acknowledge with the store only after coins are credited, so a crash
    // in between leaves the purchase pending and this listener fires again.
    await FlutterInappPurchase.instance
        .finishTransaction(purchase: purchase, isConsumable: true);

    if (!mounted) return;
    setState(() => _purchasingId = null);
    if (coins != null) _showPurchaseSuccessDialog(context, coins);
  }

  /// Whether the daily rewarded-ad limit still has room.
  ///
  /// Fails open: if the count can't be read (signed out, offline, rules), a
  /// dead button is a worse outcome than an extra watch, and the watch is
  /// still recorded on the write side so the limit re-applies by itself.
  //--------------------------------------------------
  // Rewarded ad logic
  //--------------------------------------------------
  Future<bool> _canWatchAdToday() async {
    if (DatabaseService.instance.userId == null) return true;
    try {
      return await DatabaseService.instance
          .canWatchRewardedAdToday(AdConfig.adLimit);
    } catch (e) {
      debugPrint('[Shop] Could not read today\'s ad watch count: $e');
      return true;
    }
  }

  void _preloadRewardedAdIfAllowed() async {
    if (!AdConfig.rewardedAdEnabled ||
        AdConfig.adProvider != AdProviderType.google) {
      return;
    }
    if (await _canWatchAdToday()) _loadRewardedAd();
  }

  void _loadRewardedAd() {
    if (_isLoadingRewardedAd || _rewardedAd != null) return;
    _isLoadingRewardedAd = true;
    _rewardedAdRetryTimer?.cancel();
    _rewardedAdRetryTimer = null;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdID,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingRewardedAd = false;
          _rewardedAdFailureCount = 0;
          if (!mounted) {
            ad.dispose();
            return;
          }
          if (_isWaitingForRewardedAd) {
            setState(() => _isWaitingForRewardedAd = false);
            _showRewardedAd(ad);
          } else {
            setState(() => _rewardedAd = ad);
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewardedAd = false;
          debugPrint('[Shop] Rewarded ad failed to load: $error');
          if (!mounted) return;
          if (_isWaitingForRewardedAd) {
            setState(() => _isWaitingForRewardedAd = false);
            _showSnack(context, context.tr('adNotLoaded'));
          }
          _scheduleRewardedAdRetry();
        },
      ),
    );
  }

  void _scheduleRewardedAdRetry() {
    _rewardedAdRetryTimer?.cancel();
    final Duration delay = _adRetryDelays[
        _rewardedAdFailureCount.clamp(0, _adRetryDelays.length - 1)];
    _rewardedAdFailureCount++;
    _rewardedAdRetryTimer = Timer(delay, () {
      _rewardedAdRetryTimer = null;
      if (mounted) _loadRewardedAd();
    });
  }

  void _showRewardedAd(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadRewardedAdIfAllowed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[Shop] Rewarded ad failed to show: $error');
        ad.dispose();
        if (mounted) _showSnack(context, context.tr('adNotLoaded'));
        _preloadRewardedAdIfAllowed();
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) => _grantAdReward(context));
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showPurchaseSuccessDialog(BuildContext context, int coins) {
    return UiUtils.showDialog(
      context,
      child: CustomDialogBox(
        title: context.tr('congratulations'),
        hideCloseButton: true,
        buttons: [
          DialogButton(
            title: context.tr('ok'),
            color: context.color.tertiary,
            textColor: Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ],
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.sizes.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImage(AppIcons.coin,
                  width: context.sizes.lg, height: context.sizes.lg),
              SizedBox(width: 6.r(context)),
              Flexible(
                child: CustomText(
                  context.tr('youGotCoins', params: {'coins': '$coins'}),
                  fontSize: context.font.medium,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onBuy(BuildContext context, ShopItem item) async {
    if (_purchasingId != null) return;
    setState(() => _purchasingId = item.id);
    try {
      await FlutterInappPurchase.instance.requestPurchaseWithBuilder(
        build: (builder) {
          builder.ios.sku = item.id;
          builder.android.skus = [item.id];
          builder.type = ProductQueryType.InApp;
        },
      );
    } catch (e) {
      if (mounted) setState(() => _purchasingId = null);
      if (context.mounted) {
        _showSnack(context, context.tr('purchaseFailed'));
      }
    }
  }

  Future<void> _watchAd(BuildContext context) async {
    if (_isWaitingForRewardedAd) return;

    final allowed = await _canWatchAdToday();
    if (!context.mounted) return;
    if (!allowed) {
      debugPrint('[Shop] Watch-ad blocked: daily limit reached');
      _showSnack(context, context.tr('youReachedAtTodaysAdLimit'));
      return;
    }

    if (AdConfig.adProvider == AdProviderType.google) {
      final ad = _rewardedAd;
      if (ad != null) {
        // Rewarded ads are single-use: clear the cached reference now so a
        // second tap while this one is showing can't reuse or double-show it.
        setState(() => _rewardedAd = null);
        _showRewardedAd(ad);
        return;
      }
      // The preload failed or is still in flight. Wait for it and show the ad
      // as soon as it arrives, rather than sending the user away to tap again.
      setState(() => _isWaitingForRewardedAd = true);
      _loadRewardedAd();
    } else {
      UnityAds.load(
        placementId: AdConfig.unityRewardedPlacementId,
        onComplete: (placementId) {
          UnityAds.showVideoAd(
            placementId: placementId,
            onComplete: (placementId) => _grantAdReward(context),
            onFailed: (placementId, error, message) {
              if (context.mounted) {
                _showSnack(context, context.tr('adNotLoaded'));
              }
            },
          );
        },
        onFailed: (placementId, error, message) {
          if (context.mounted) _showSnack(context, context.tr('adNotLoaded'));
        },
      );
    }
  }

  Future<void> _grantAdReward(BuildContext context) async {
    final String? uid = DatabaseService.instance.userId;
    if (uid == null) {
      debugPrint('[Shop] Ad reward earned while signed out; nothing credited');
      return;
    }
    try {
      await DatabaseService.instance.creditCoins(uid, AdConfig.adRewardAmount);
      await DatabaseService.instance.recordRewardedAdWatch();
    } catch (e) {
      debugPrint('[Shop] Could not credit the ad reward: $e');
      if (!context.mounted) return;
      _showSnack(context, context.tr('somethingWentWrongTryAgain'));
      return;
    }
    if (!context.mounted) return;
    _showSnack(context, context.tr('rewardAmountAddedSuccessfully'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        title: CustomText(context.tr('shop'),
            fontSize: context.font.xL,
            fontWeight: FontWeight.w700,
            color: AppColors.white),
        backgroundColor: context.color.surfaceContainer,
        surfaceTintColor: context.color.surfaceContainer,
      ),
      body: Builder(builder: (context) {
        final catalog = _catalog;
        if (catalog == null) {
          return Center(
              child: CircularProgressIndicator(color: context.color.secondary));
        }
        // Hide the "watch ad" tile entirely when rewarded ads are disabled server-side.
        final items = AdConfig.rewardedAdEnabled
            ? catalog
            : catalog.where((item) => !item.isAd).toList();

        return GridView.builder(
          padding: EdgeInsets.only(
            left: context.sizes.md,
            right: context.sizes.md,
            top: context.sizes.md,
            bottom: context.sizes.md + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.r(context),
            mainAxisSpacing: 16.r(context),
            mainAxisExtent: 199.r(context),
          ),
          itemBuilder: (context, index) {
            final ShopItem item = items[index];
            return ShopItemCard(
              item: item,
              product: _products[item.id],
              isPurchasing: _purchasingId == item.id,
              isWaitingForRewardedAd: _isWaitingForRewardedAd,
              onBuy: () => _onBuy(context, item),
              onWatchAd: () => _watchAd(context),
            );
          },
        );
      }),
    );
  }
}
