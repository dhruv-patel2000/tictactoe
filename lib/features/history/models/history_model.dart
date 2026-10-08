import 'package:flutter/widgets.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';

/// Outcome of a single match, used to label and colour a history row.
enum HistoryStatus {
  won('won'),
  lost('lost'),
  tie('tie'),
  quited('quited');

  final String labelKey;
  const HistoryStatus(this.labelKey);

  String label(BuildContext context) => context.tr(labelKey);

  static HistoryStatus fromString(String? value) {
    return HistoryStatus.values.firstWhere(
      (status) => status.name == value?.toLowerCase(),
      orElse: () => HistoryStatus.lost,
    );
  }
}

/// Model: a single row in the user's match history (coins won/lost, result,
/// timestamp), stored/read via history_repository.
class HistoryModel {
  /// Coins won (positive) or lost (negative) in this match.
  final int amount;
  final HistoryStatus status;
  final DateTime dateTime;

  const HistoryModel({
    required this.amount,
    required this.status,
    required this.dateTime,
  });

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      status: HistoryStatus.fromString(map['status'] as String?),
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'status': status.name,
      'timestamp': dateTime.millisecondsSinceEpoch,
    };
  }
}
