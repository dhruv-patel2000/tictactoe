import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/core/constants/ad_config.dart';

/// The kind of shop entry — a paid coin pack or a rewarded-ad entry.
enum ShopItemType {
  /// Purchasable coin pack with a real-money price.
  purchase,

  /// Free coins earned by watching a rewarded ad.
  rewardedAd;

  static ShopItemType fromString(String? value) {
    return ShopItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShopItemType.purchase,
    );
  }
}

/// A single product shown on the Shop screen.
///
/// Kept generic so the same model backs both paid coin packs and the
/// "watch an ad for coins" entry. Mirrors a future remote-config / store
/// shape via [fromMap]/[toMap] so the dummy list can be swapped for a stream.
class ShopItem {
  /// For [ShopItemType.purchase] this is the store product id (must match
  /// the Play Console / App Store listing) — the shop screen fetches live
  /// pricing for it via `flutter_inapp_purchase`.
  final String id;

  /// Coins granted when the item is purchased / the ad is watched.
  final int coins;

  /// Fallback USD price shown until the real store price has loaded, or if
  /// the store lookup fails. `null` for [ShopItemType.rewardedAd].
  final double? priceUsd;

  final ShopItemType type;

  /// Optional product artwork (asset path or URL). When `null` the screen
  /// falls back to a coin placeholder.
  final String? image;

  const ShopItem({
    required this.id,
    required this.coins,
    required this.type,
    this.priceUsd,
    this.image,
  });

  /// e.g. "100 Coins".
  String get title => '$coins Coins';

  /// e.g. "2 USD"; empty for rewarded-ad items.
  String get priceLabel =>
      priceUsd == null ? '' : '${priceUsd!.toStringAsFixed(0)} USD';

  bool get isAd => type == ShopItemType.rewardedAd;

  /// Tiered coin artwork chosen by how many coins the pack grants:
  /// small/medium/large stacks for lighter packs, then bags for the
  /// heaviest ones. Used as the fallback when [image] is not provided.
  String get coinArtwork {
    if (coins >= 5000) return AppIcons.coinBagLarge;
    if (coins >= 1000) return AppIcons.coinBagSmall;
    if (coins >= 500) return AppIcons.coinStackLarge;
    if (coins >= 200) return AppIcons.coinStackMedium;
    return AppIcons.coinStackSmall;
  }

  factory ShopItem.fromMap(String id, Map<String, dynamic> map) {
    return ShopItem(
      id: id,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      priceUsd: (map['priceUsd'] as num?)?.toDouble(),
      type: ShopItemType.fromString(map['type']),
      image: map['image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coins': coins,
      'priceUsd': priceUsd,
      'type': type.name,
      'image': image,
    };
  }

  /// Default catalogue, used until `shopItems` is read from Firebase.
  /// Ids match the real Play Console / App Store IAP product listings —
  /// see [AdConfig.coinProductIds].
  static List<ShopItem> get dummy => const [
        ShopItem(
            id: '100_coins',
            coins: 100,
            type: ShopItemType.purchase,
            priceUsd: 2),
        ShopItem(
            id: '500_coins',
            coins: 500,
            type: ShopItemType.purchase,
            priceUsd: 10),
        ShopItem(
            id: '1000_coins',
            coins: 1000,
            type: ShopItemType.purchase,
            priceUsd: 20),
        ShopItem(
            id: '2000_coins',
            coins: 2000,
            type: ShopItemType.purchase,
            priceUsd: 35),
        ShopItem(
            id: '5000_coins',
            coins: 5000,
            type: ShopItemType.purchase,
            priceUsd: 75),
        ShopItem(
            id: '10000_coins',
            coins: 10000,
            type: ShopItemType.purchase,
            priceUsd: 140),
        ShopItem(
            id: 'watchAd',
            coins: AdConfig.adRewardAmount,
            type: ShopItemType.rewardedAd),
      ];
}
