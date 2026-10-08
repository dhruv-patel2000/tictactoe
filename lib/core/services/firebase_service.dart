import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/features/game/models/game_model.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';
import 'package:tic_tac_toe/features/history/models/history_model.dart';
import 'package:tic_tac_toe/features/shop/models/shop_item_model.dart';
import 'package:tic_tac_toe/features/skins/models/skin_model.dart';
import 'package:tic_tac_toe/commons/models/user_model.dart';
import 'package:tic_tac_toe/commons/repositories/coin_repository.dart';
import 'package:tic_tac_toe/features/game/repositories/game_repository.dart';
import 'package:tic_tac_toe/features/history/repositories/history_repository.dart';
import 'package:tic_tac_toe/features/leaderboard/repositories/leaderboard_ranking.dart';
import 'package:tic_tac_toe/features/skins/repositories/skin_repository.dart';

export 'package:tic_tac_toe/features/game/repositories/game_repository.dart'
    show InsufficientCoinsException;

/// Facade over the current user's Firebase-backed profile plus the
/// [CoinRepository], [GameRepository], [HistoryRepository] and
/// [SkinRepository] data-access classes. Kept as a single entry point so
/// existing call sites don't need to know about the split; each concern's
/// actual logic lives in its own repository.
class DatabaseService {
  final FirebaseDatabase database = FirebaseDatabase.instance;
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  late final CoinRepository _coins = CoinRepository(database);
  late final SkinRepository _skins = SkinRepository(database);
  late final HistoryRepository _history = HistoryRepository(database);
  late final GameRepository _game = GameRepository(database, _coins, _history);

  Skin get activeSkin => _skins.activeSkin;

  static DatabaseService? _instance;

  static DatabaseService get instance {
    _instance ??= DatabaseService();
    return _instance!;
  }

  DatabaseReference get currentUser {
    return database.ref().child("users").child(userId!)..keepSynced(true);
  }

  DatabaseReference get userSkins {
    return database.ref().child("userSkins").child(userId!);
  }

  Future<bool> checkIsUserExists() async {
    if (userId != null) {
      return (await currentUser.once()).snapshot.value != null;
    }
    return false;
  }

  /// Wipes this user's data nodes ahead of deleting the Firebase Auth account
  /// itself, so no orphaned `users`/`userSkins` records are left behind.
  Future<void> deleteAccountData() async {
    await currentUser.remove();
    await userSkins.remove();
  }

  Future<void> createUser(UserModel user) async {
    currentUser.set(user.toMap());

    await _skins.setDefaultSkins(userId!);
    await getActiveSkin();
  }

  Future<UserModel> getUser() async {
    await getActiveSkin();

    final user = UserModel.fromMap(
        Map.from((await currentUser.once()).snapshot.value as dynamic))
      ..email = FirebaseAuth.instance.currentUser?.email;
    return _ensureRankKey(user);
  }

  /// Users created before [UserModel.createdAt]/`rankKey` existed have no value
  /// to order the leaderboard by. Backfill them once, using the Firebase Auth
  /// account-creation time so the "earlier joiner wins ties" rule stays honest,
  /// and return the user with [UserModel.createdAt] populated.
  Future<UserModel> _ensureRankKey(UserModel user) async {
    if (user.createdAt != null) return user;
    final int created =
        (FirebaseAuth.instance.currentUser?.metadata.creationTime ??
                    DateTime.now())
                .millisecondsSinceEpoch ~/
            1000;
    await currentUser.update({
      'createdAt': created,
      'rankKey': rankKeyFor(score: user.score ?? 0, createdAtSeconds: created),
    });
    return user.copyWith(createdAt: created);
  }

  /// Renames the current user, writing to both the DB record the app reads
  /// from (via [streamUser]) and the Firebase Auth display name so every
  /// surface stays consistent.
  Future<void> updateUsername(String username) async {
    await currentUser.update({'username': username});
    await FirebaseAuth.instance.currentUser?.updateDisplayName(username);
  }

  /// Uploads [file] to Cloud Storage under `userProfiles/`, points the user's
  /// `profilePic` at the resulting download URL, and mirrors it onto the
  /// Firebase Auth photo URL so avatars everywhere update. Returns the new URL.
  Future<String> uploadProfilePic(File file) async {
    final String fileName =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref =
        FirebaseStorage.instance.ref().child('userProfiles').child(fileName);
    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'picked-file-path': fileName},
    );
    final TaskSnapshot task = await ref.putFile(file, metadata);
    final String url = await task.ref.getDownloadURL();
    await currentUser.update({'profilePic': url});
    await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
    return url;
  }

  /// Emits the current user every time the underlying node changes so screens
  /// (profile card, leaderboard, shop) reflect score/coin/match updates live.
  /// Email isn't stored in the DB, so it's re-attached from FirebaseAuth like
  /// [getUser] does. Null snapshots (e.g. node deleted) are skipped.
  Stream<UserModel> streamUser() {
    return currentUser.onValue
        .map((event) => event.snapshot.value)
        .where((value) => value != null)
        .map((value) => UserModel.fromMap(Map.from(value as dynamic))
          ..email = FirebaseAuth.instance.currentUser?.email);
  }

  // ── Coin economy ─────────────────────────────────────────────────────────

  Future<bool> debitCoins(String uid, int amount) =>
      _coins.debitCoins(uid, amount);

  Future<void> creditCoins(String uid, int amount) =>
      _coins.creditCoins(uid, amount);

  Future<bool> canWatchRewardedAdToday(int limit) =>
      _coins.canWatchRewardedAdToday(userId!, limit);

  Future<void> recordRewardedAdWatch() => _coins.recordRewardedAdWatch(userId!);

  Future<bool> claimPurchase(String uid, String purchaseId) =>
      _coins.claimPurchase(uid, purchaseId);

  // ── Multiplayer game ─────────────────────────────────────────────────────

  Future<({GameConnection connection, GameModel game})> connectGame({
    required Player player,
    required int matrixSize,
    required int entryFee,
    required int rounds,
  }) =>
      _game.connectGame(
        player: player,
        matrixSize: matrixSize,
        entryFee: entryFee,
        rounds: rounds,
      );

  Future<bool> closeGame(String gameKey) => _game.closeGame(gameKey);

  Future<void> listenOpponentJoin(
          String gameKey, Function(Player opponent) onOpponentJoined) =>
      _game.listenOpponentJoin(gameKey, onOpponentJoined);

  Future<void> createGame(GameModel model) => _game.createGame(model);

  Future<GameModel?> fetchAvailableGames({
    required int entryFee,
    required int rounds,
    required int matrixSize,
  }) =>
      _game.fetchAvailableGames(
        entryFee: entryFee,
        rounds: rounds,
        matrixSize: matrixSize,
        excludingPlayerId: userId ?? '',
      );

  Future<GameModel> getGame(String gameKey) => _game.getGame(gameKey);

  Future<void> updateMove(String gameKey, int row, int column, Player player) =>
      _game.updateMove(gameKey, row, column, player);

  StreamSubscription<DatabaseEvent> listenGame(
          String gameKey, Function(DatabaseEvent game) onGameUpdate) =>
      _game.listenGame(gameKey, onGameUpdate);

  Future<void> nextPlayer(String gameKey, String nextPlayer) =>
      _game.nextPlayer(gameKey, nextPlayer);

  Future<void> setGameResult(String gameKey, Map<String, dynamic> result) =>
      _game.setGameResult(gameKey, result);

  Future<int> updateRound(String gameKey, int boardSize) =>
      _game.updateRound(gameKey, boardSize);

  // ── History ──────────────────────────────────────────────────────────────

  Stream<List<HistoryModel>> streamHistory() => _history.streamHistory(userId!);

  // ── Skins ────────────────────────────────────────────────────────────────

  Future<void> activateSkin(Skin skin) => _skins.activateSkin(userId!, skin);

  Future<bool> purchaseSkin(Skin skin) async {
    if (skin.price > 0) {
      final funded = await _coins.debitCoins(userId!, skin.price);
      if (!funded) return false;
    }
    await _skins.updateSkin(userId!, skin, 'active');
    return true;
  }

  Future<void> updateSkin(Skin skin, String newStatus) =>
      _skins.updateSkin(userId!, skin, newStatus);

  Future<Skin?> getActiveSkin() => _skins.getActiveSkin(userId!);

  Stream<List<Skin>> streamAvailableSkins() => _skins.streamAvailableSkins();

  // ── Shop ─────────────────────────────────────────────────────────────────

  Stream<List<ShopItem>> streamShopItems() {
    return database.ref().child('shopItems').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return ShopItem.dummy;
      final List<ShopItem> loaded = [];
      data.forEach((key, value) {
        loaded.add(ShopItem.fromMap(key, Map<String, dynamic>.from(value)));
      });
      // Always show a "watch ad" tile even if the backend hasn't configured
      // one, by falling back to the bundled dummy entry.
      if (!loaded.any((item) => item.isAd)) {
        loaded.add(
          ShopItem.dummy.firstWhere((item) => item.isAd),
        );
      }
      return loaded;
    });
  }
}
