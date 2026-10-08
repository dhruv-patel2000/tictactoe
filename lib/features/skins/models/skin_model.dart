// ignore_for_file: public_member_api_docs, sort_constructors_first
/// Model: a purchasable/selectable X-O skin pair, its unlock price, and
/// whether it's the player's currently active skin.
class Skin {
  final String id;
  final String name;
  final String skinX;
  final String skinO;
  // 'active' when this is the player's currently equipped skin, '' otherwise
  // (mirrors the string flag stored in Firebase rather than a bool).
  String? selectedStatus;
  final String? priceId; // Added for IAP

  /// Coin cost to unlock this skin. 0 means free/already owned.
  final int price;

  Skin({
    required this.id,
    required this.name,
    required this.skinX,
    required this.skinO,
    this.selectedStatus,
    this.priceId,
    this.price = 0,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'skinXUrl': skinX,
      'skinOUrl': skinO,
      'selectedStatus': selectedStatus,
      'id': id,
      'priceId': priceId,
      'price': price,
    };
  }

  factory Skin.fromMap(Map<dynamic, dynamic> map) {
    return Skin(
      name: map['name'] ?? map['itemid'] ?? '',
      skinX: map['skinXUrl'] ?? map['skinX'] ?? '',
      skinO: map['skinOUrl'] ?? map['skinO'] ?? '',
      selectedStatus:
          map['selectedStatus']?.toString().toLowerCase() == 'active'
              ? 'active'
              : '',
      id: map['id'] ?? '',
      priceId: map['priceId'],
      price: (map['price'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() {
    return 'Skin(name: $name, skinX: $skinX, skinO: $skinO, selectedStatus: $selectedStatus, id: $id, price: $price)';
  }
}
