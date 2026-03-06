import 'package:cloud_firestore/cloud_firestore.dart';

class DayRecord {
  final String id; // format: "YYYY-MM-DD"
  final DateTime date;
  final double allowance;
  final double totalSpent;
  final double remaining;
  final double withdrawnFromSavings;

  DayRecord({
    required this.id,
    required this.date,
    this.allowance = 0.0,
    this.totalSpent = 0.0,
    this.remaining = 0.0,
    this.withdrawnFromSavings = 0.0,
  });

  factory DayRecord.fromMap(Map<String, dynamic> data, String documentId) {
    return DayRecord(
      id: documentId,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      allowance: (data['allowance'] ?? 0.0).toDouble(),
      totalSpent: (data['totalSpent'] ?? 0.0).toDouble(),
      remaining: (data['remaining'] ?? 0.0).toDouble(),
      withdrawnFromSavings: (data['withdrawnFromSavings'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'allowance': allowance,
      'totalSpent': totalSpent,
      'remaining': remaining,
      'withdrawnFromSavings': withdrawnFromSavings,
    };
  }
}
