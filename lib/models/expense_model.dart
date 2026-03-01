import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime time;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.time,
  });

  factory Expense.fromMap(Map<String, dynamic> data, String documentId) {
    return Expense(
      id: documentId,
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'time': Timestamp.fromDate(time),
    };
  }
}
