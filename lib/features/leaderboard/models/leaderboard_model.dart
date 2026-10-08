// Model: one entry on the leaderboard (user, score, rank); fetched/ranked
// via leaderboard_repository and leaderboard_ranking.
class LeaderboardModel {
  final String userId;
  final String name;
  final int score;
  final String? profilePic;

  final int? createdAt;

  // Precomputed sortable key from leaderboard_ranking.dart (score + tiebreak
  // packed into one number); null for legacy rows written before it existed.
  final int? rankKey;

  // Position on the board (1-based), filled in by rankUsers() - not present
  // on raw data read straight from Firebase.
  final int? rank;

  const LeaderboardModel({
    this.userId = '',
    required this.name,
    required this.score,
    this.profilePic,
    this.createdAt,
    this.rankKey,
    this.rank,
  });

  factory LeaderboardModel.fromMap(Map<String, dynamic> map,
      {String userId = ''}) {
    return LeaderboardModel(
      userId: userId.isNotEmpty ? userId : (map['userid'] ?? ''),
      name: map['username'] ?? '',
      score: _toInt(map['score']) ?? 0,
      profilePic: map['profilePic'],
      createdAt: _toInt(map['createdAt']),
      rankKey: _toInt(map['rankKey']),
    );
  }

  LeaderboardModel copyWith({int? rank}) {
    return LeaderboardModel(
      userId: userId,
      name: name,
      score: score,
      profilePic: profilePic,
      createdAt: createdAt,
      rankKey: rankKey,
      rank: rank ?? this.rank,
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? num.tryParse(value)?.toInt();
  }
  return null;
}
