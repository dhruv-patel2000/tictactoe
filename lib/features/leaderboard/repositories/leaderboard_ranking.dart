import 'package:tic_tac_toe/features/leaderboard/models/leaderboard_model.dart';

/// Pure, Firebase-free ranking logic for the leaderboard.
///
/// This is the single place to change *how* players are ordered or *how* a rank
/// number is assigned. It takes plain models in and returns plain models out,
/// so it needs no Firebase and is trivial to unit-test or swap. Data access
/// lives in `leaderboard_repository.dart`; the UI never calls this directly.

/// Weight that packs `(score, joinDate)` into a single sortable [rankKeyFor].
///
/// Players are ordered by score first and, when scores tie (e.g. everyone at
/// 0 before any match is scored), by who joined first. Encoding both into one
/// number lets Firebase order/limit server-side with a single `orderByChild`,
/// so a player's rank can be read with a bounded query instead of downloading
/// every user.
///
/// Constraints:
///  • must exceed the largest plausible `createdAt` in *seconds* so the date
///    only ever breaks ties between equal scores — `4e9` is valid until ~2096;
///  • `score * _scoreWeight` must stay below 2^53 (Firebase stores numbers as
///    doubles), which caps exact scores at ~2.25 million — plenty here.
const int _scoreWeight = 4000000000;

/// Single sortable rank key — **higher is better**. A higher score dominates;
/// among equal scores the earlier joiner (smaller [createdAtSeconds]) gets the
/// larger key, so "first in the app" ranks ahead. Change this function to
/// change the tiebreak rule everywhere at once.
int rankKeyFor({required int score, required int createdAtSeconds}) =>
    score * _scoreWeight - createdAtSeconds;

/// The key actually used for ordering: a stored `rankKey` when present, else
/// derived on the fly so legacy users (written before `rankKey` existed) still
/// sort correctly until they're backfilled.
int _effectiveKey(LeaderboardModel user) =>
    user.rankKey ??
    rankKeyFor(score: user.score, createdAtSeconds: user.createdAt ?? 0);

/// Returns [users] sorted best-first by [rankKeyFor] with
/// [LeaderboardModel.rank] filled in (1, 2, 3, …). Users who never scored
/// (`score == 0`, e.g. an install that hasn't played a match) are dropped
/// before ranking — same as the previous leaderboard — so they don't inflate
/// everyone else's rank number and never appear as "ranked" themselves.
/// The repository calls this on both the board's data and on a full `users`
/// read to find one player's own rank, so the list and the "Your Rank" card
/// always agree.
List<LeaderboardModel> rankUsers(List<LeaderboardModel> users) {
  final sorted = users.where((u) => u.score != 0).toList()
    ..sort((a, b) => _effectiveKey(b).compareTo(_effectiveKey(a)));
  return [
    for (var i = 0; i < sorted.length; i++) sorted[i].copyWith(rank: i + 1),
  ];
}
