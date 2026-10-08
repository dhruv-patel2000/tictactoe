import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/features/leaderboard/repositories/leaderboard_ranking.dart';

/// Model: the app's user profile (identity, coins, score, match stats),
/// synced to Firebase and consumed by AuthenticationBloc.
class UserModel {
  final String username;
  final String userId;
  String? email;
  final int? matchPlayed;
  final int? matchWon;
  final String profilePic;
  final int? coin;
  final int? score;
  // 'AUTHENTICATED' or 'GUEST' - which sign-in path created this account
  // (see AuthenticationBloc).
  final String type;

  /// Seconds since epoch when the account was created. Used by the leaderboard
  /// to break ties between equal scores (earlier joiner ranks higher).
  final int? createdAt;

  UserModel({
    required this.username,
    required this.userId,
    this.matchPlayed,
    this.matchWon,
    required this.profilePic,
    this.coin,
    this.score,
    required this.type,
    this.email,
    this.createdAt,
  });

  // Convert the model to a Map
  Map<String, dynamic> toMap() {
    ///Please do not store email
    final int created =
        createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return {
      "username": username,
      "userid": userId,
      "matchplayed": matchPlayed ?? 0,
      "matchwon": matchWon ?? 0,
      "profilePic": profilePic,
      "coin": coin ?? 500,
      "score": score ?? 0,
      "type": type,
      "createdAt": created,
      // Stored so the leaderboard can order/limit server-side; must be rewritten
      // alongside `score` whenever the score changes (see [rankKeyFor]).
      "rankKey": rankKeyFor(score: score ?? 0, createdAtSeconds: created),
    };
  }

  UserModel copyWith({int? createdAt}) {
    return UserModel(
      username: username,
      userId: userId,
      matchPlayed: matchPlayed,
      matchWon: matchWon,
      profilePic: profilePic,
      coin: coin,
      score: score,
      type: type,
      email: email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Create a model from a Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map["username"] ?? "",
      userId: map["userid"] ?? "",
      matchPlayed: map["matchplayed"] ?? 0,
      matchWon: map["matchwon"] ?? 0,
      profilePic: (map["profilePic"] == '' || map["profilePic"] == null)
          ? AppIcons.guest
          : map['profilePic'],
      coin: map["coin"] ?? 500,
      score: map["score"] ?? 0,
      type: map["type"] ?? "",
      email: map["email"],
      createdAt: (map["createdAt"] as num?)?.toInt(),
    );
  }
}
