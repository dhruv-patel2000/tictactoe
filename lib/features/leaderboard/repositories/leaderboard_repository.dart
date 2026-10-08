import 'package:firebase_database/firebase_database.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/features/leaderboard/models/leaderboard_model.dart';
import 'package:tic_tac_toe/features/leaderboard/repositories/leaderboard_ranking.dart';

/// A player's resolved rank. [isCapped] is true when the real rank is worse
/// than [LeaderboardRepository.rankCap] (or the player wasn't found within
/// the top [LeaderboardRepository.rankCap] at all).
typedef UserRank = ({int rank, bool isCapped});

/// Opaque cursor returned by [LeaderboardRepository.fetchLeaderboardPage].
/// Pass a page's [LeaderboardPage.nextCursor] straight back in to fetch the
/// page after it; `null` means there's nothing further.
class LeaderboardCursor {
  const LeaderboardCursor._(this._score, this._key);
  final int _score;
  final String _key;
}

/// One page of the leaderboard: [players] ranked best-first with
/// [LeaderboardModel.rank] already absolute (continues from the previous
/// page), plus [nextCursor] to fetch the page after this one.
typedef LeaderboardPage = ({
  List<LeaderboardModel> players,
  LeaderboardCursor? nextCursor,
});

/// Data access for the leaderboard.
///
/// The board and a single player's own rank both order by
/// `orderByChild('score')` rather than the combined `rankKey`. `rankKey` is
/// only written once a user logs in post-rollout or finishes a match (see
/// `_ensureRankKey`/`_recordStats` in `firebase_service.dart`), so on a live
/// table most existing rows still have `rankKey == null`. Firebase's
/// `orderByChild` on a field that's null for almost every row — with no
/// server `.indexOn` rule for it — resolves client-side off an incomplete
/// cache, and different query windows can each settle on a different,
/// inconsistent slice of the same data (observed: the same player at rank 5
/// in one window and rank 25 in another on an identical 60-row table).
/// `score` is populated on every row from day one, so ordering by it is
/// deterministic; the `rankKey`/`createdAt` tiebreak between equal scores is
/// still applied locally, in [rankUsers], to whatever window a query returns.
///
/// Ranking math lives in the pure `leaderboard_ranking.dart`; UI consumes only
/// the methods below and never touches Firebase or ordering directly.
class LeaderboardRepository {
  LeaderboardRepository({DatabaseService? service})
      : _db = service ?? DatabaseService.instance;

  final DatabaseService _db;

  /// Default page size for [fetchLeaderboardPage].
  static const int defaultLimit = 100;

  /// Ranks worse than this are reported as capped, bounding every rank lookup
  /// to at most [rankCap] downloaded rows regardless of total user count.
  static const int rankCap = 999;

  Query get _byScore => _db.database.ref().child('users').orderByChild('score');

  /// Fetches one page of [limit] players ordered best-first by score,
  /// ranked starting at [startRank] (1 for the first page; pass
  /// `previousStartRank + previousPage.players.length` for the next one, so
  /// [LeaderboardModel.rank] stays continuous across pages). Omit [cursor]
  /// for the first page; pass the previous page's [LeaderboardPage.nextCursor]
  /// to fetch the next one. Firebase orders ascending, so pages are read from
  /// the bottom of that ascending order upward via `limitToLast`/`endBefore`,
  /// then reversed to best-first here.
  Future<LeaderboardPage> fetchLeaderboardPage({
    int limit = defaultLimit,
    LeaderboardCursor? cursor,
    int startRank = 1,
  }) async {
    Query query = _byScore;
    if (cursor != null) {
      query = query.endBefore(cursor._score, key: cursor._key);
    }
    final snapshot = (await query.limitToLast(limit).once()).snapshot;

    // Ascending order as Firebase returned it (worst-in-page first) — the
    // cursor for the *next* page must be this page's true lower boundary,
    // independent of any local tiebreak reordering below.
    final ascending = _parse(snapshot);
    final hasMore = ascending.length >= limit;
    final nextCursor = hasMore && ascending.isNotEmpty
        ? LeaderboardCursor._(ascending.first.score, ascending.first.userId)
        : null;

    final players = rankUsers(ascending)
        .asMap()
        .entries
        .map((e) => e.value.copyWith(rank: startRank + e.key))
        .toList();

    return (players: players, nextCursor: nextCursor);
  }

  /// Live rank of the user with id [userId], looked up within the top
  /// [rankCap] players by score. A player outside that window is reported as
  /// capped rather than downloading the rest of the table to find their exact
  /// position.
  Stream<UserRank?> streamUserRank(String userId) {
    return _byScore
        .limitToLast(rankCap)
        .onValue
        .map((e) => _rankOf(e.snapshot, userId));
  }

  /// One-shot variant of [streamUserRank].
  Future<UserRank?> fetchUserRank(String userId) async {
    return _rankOf(
        (await _byScore.limitToLast(rankCap).once()).snapshot, userId);
  }

  UserRank? _rankOf(DataSnapshot snapshot, String userId) {
    final ranked = rankUsers(_parse(snapshot));
    for (final player in ranked) {
      if (player.userId == userId) {
        return (rank: player.rank!, isCapped: player.rank! > rankCap);
      }
    }
    // Not among the top rankCap: either genuinely ranked worse, or the
    // snapshot window didn't include them. Either way, report as capped
    // rather than falling back to a full-table read.
    return ranked.isEmpty ? null : (rank: rankCap + 1, isCapped: true);
  }

  List<LeaderboardModel> _parse(DataSnapshot snapshot) {
    return [
      for (final child in snapshot.children)
        if (child.value is Map)
          LeaderboardModel.fromMap(
            Map<String, dynamic>.from(child.value as Map),
            userId: child.key ?? '',
          ),
    ];
  }
}
