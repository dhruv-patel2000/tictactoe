import 'package:firebase_database/firebase_database.dart';
import 'package:tic_tac_toe/features/history/models/history_model.dart';

/// Match-history data access.
class HistoryRepository {
  HistoryRepository(this._database);

  final FirebaseDatabase _database;

  DatabaseReference _historyRef(String uid) =>
      _database.ref().child('history').child(uid);

  /// Appends one finished-match record to [uid]'s history. [amount] is the net
  /// coin change (positive for a win, negative for a loss, 0 for a draw).
  /// Written from the single result claimer for both players, like the payout.
  Future<void> recordHistory(
      String uid, HistoryStatus status, int amount) async {
    await _historyRef(uid).push().set(HistoryModel(
          amount: amount,
          status: status,
          dateTime: DateTime.now(),
        ).toMap());
  }

  /// Streams the current user's match history, newest first, so the History
  /// screen reflects results live as games settle.
  Stream<List<HistoryModel>> streamHistory(String uid) {
    return _historyRef(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return <HistoryModel>[];
      final list = (value as Map)
          .values
          .map((e) => HistoryModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    });
  }
}
