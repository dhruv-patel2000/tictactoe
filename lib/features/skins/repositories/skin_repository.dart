import 'package:firebase_database/firebase_database.dart';
import 'package:tic_tac_toe/core/constants/settings.dart';
import 'package:tic_tac_toe/features/skins/models/skin_model.dart';

/// Skin catalog, ownership, and active-skin selection data access.
class SkinRepository {
  SkinRepository(this._database);

  final FirebaseDatabase _database;
  // In-memory cache of the last skin loaded/activated for a user, so
  // `activeSkin` has something to return before the first Firebase read
  // completes.
  Skin? _activeSkin;

  Skin get activeSkin => _activeSkin ?? AppSettings.defaultSkin;

  DatabaseReference _userSkins(String uid) =>
      _database.ref().child('userSkins').child(uid);

  Future<void> setDefaultSkins(String uid) async {
    await _userSkins(uid).set([AppSettings.defaultSkin.toMap()]);
  }

  Future<void> activateSkin(String uid, Skin skin) async {
    await updateSkin(uid, skin, 'active');
  }

  /// Maps a pre-redesign purchase's `itemid` (the old catalog's display name)
  /// to its slot in the current catalog. The redesign only reskinned the same
  /// 9 slots (new art, new names, new ids) — it didn't add or remove any — so
  /// position-for-position the old and new catalogs line up 1:1.
  static const Map<String, String> _legacySkinIdByName = {
    'DORA Classic': 'cross',
    'DORA Plus': 'enhance',
    'DORA Square': 'box',
    'DORA Polygon': 'pentagon',
    'DORA Hexagon': 'hex',
    'DORA Octagon': 'shield',
    'DORA Triangle': 'pyramid',
    'DORA Diamond': 'crystal',
    'DORA Offer': 'offer',
  };

  /// Before the redesign, `userSkins/{uid}` was a push()-keyed Map of
  /// `{itemid, itemx, itemo, selectedStatus: "Active"/"Deactive"}`. The
  /// redesign switched it to a List of the current [Skin] schema, which
  /// breaks [getActiveSkin]'s `as List` cast and makes every legacy purchase
  /// invisible.
  ///
  /// Once a node has been converted to a List, Firebase reports it as a List
  /// only while every child key is a sequential index. If the *old* app is
  /// used afterwards (same account, both apps installed) it `push()`es a new
  /// legacy-shaped child under a random key, and the node reads back as a
  /// Map again — mixing legacy entries with already-current ones. Rebuild
  /// the node from every entry we find (legacy or current, deduping by id
  /// and never letting an already-active skin be knocked back to inactive)
  /// so a purchase made on either app survives, instead of the current-app
  /// entries getting silently dropped because they don't look "legacy".
  Future<void> _migrateLegacySkinsIfNeeded(String uid) async {
    final value = (await _userSkins(uid).get()).value;
    if (value == null || value is List) return;

    final Map<String, Skin> byId = {};
    void keep(Skin skin) {
      if (skin.id.isEmpty) return;
      final existing = byId[skin.id];
      if (existing != null && existing.selectedStatus == 'active') return;
      byId[skin.id] = skin;
    }

    for (final entry in Map.from(value as Map).values) {
      final Map item = Map.from(entry as Map);
      if (item.containsKey('id')) {
        // Already current schema (e.g. a List that got demoted to a Map by
        // a legacy write landing next to it) — keep as-is.
        keep(Skin.fromMap(item));
        continue;
      }

      final String id = _legacySkinIdByName[item['itemid']] ?? '';
      if (id.isEmpty) continue;
      final Skin catalogSkin = AppSettings.skins.firstWhere(
        (s) => s.id == id,
        orElse: () => AppSettings.defaultSkin,
      );
      final bool wasActive =
          item['selectedStatus']?.toString().toLowerCase() == 'active';
      keep(Skin(
        id: catalogSkin.id,
        name: catalogSkin.name,
        skinX: catalogSkin.skinX,
        skinO: catalogSkin.skinO,
        price: catalogSkin.price,
        selectedStatus: wasActive ? 'active' : '',
      ));
    }

    final List<Skin> result = byId.values.toList();
    if (result.isEmpty) {
      result.add(AppSettings.defaultSkin);
    } else if (result.every((s) => s.selectedStatus != 'active')) {
      result.first.selectedStatus = 'active';
    }

    await _userSkins(uid).set(result.map((e) => e.toMap()).toList());
  }

  Future<void> updateSkin(String uid, Skin skin, String newStatus) async {
    await _migrateLegacySkinsIfNeeded(uid);

    final List<Skin> skins = (await _userSkins(uid).get())
        .children
        .toList()
        .map((e) => Skin.fromMap(Map.from(e.value as dynamic)))
        .toList();

    // Clear whichever skin is currently active; the target skin is set
    // 'active' below. Every other skin is left untouched (they're already
    // inactive, since only one entry can be active at a time).
    for (final element in skins) {
      if (element.selectedStatus == 'active') {
        element.selectedStatus = '';
      }
    }

    final bool hasSkin = skins.any((element) => skin.id == element.id);

    if (hasSkin) {
      skins.where((element) => element.id == skin.id).forEach((e) {
        e.selectedStatus = 'active';
        _activeSkin = e;
      });
    } else {
      skins.add(skin..selectedStatus = 'active');
    }
    await _userSkins(uid).set(skins.map((e) => e.toMap()).toList());
  }

  Future<Skin?> getActiveSkin(String uid) async {
    await _migrateLegacySkinsIfNeeded(uid);

    final value = (await _userSkins(uid).get()).value;
    if (value == null) return _activeSkin;

    for (final element in (value as List)) {
      if ((element as Map)['selectedStatus'] == 'active') {
        _activeSkin = Skin.fromMap(element);
      }
    }

    return _activeSkin;
  }

  Stream<List<Skin>> streamAvailableSkins() {
    return _database.ref().child('availableSkins').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return AppSettings.skins;
      final List<Skin> loaded = [];
      data.forEach((key, value) {
        loaded.add(Skin.fromMap(value));
      });
      return loaded;
    });
  }
}
