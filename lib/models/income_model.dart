import 'package:cloud_firestore/cloud_firestore.dart';

class Income {
  final String id;
  final String description;
  final double amount;
  final DateTime time;

  Income({
    required this.id,
    required this.description,
    required this.amount,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'time': Timestamp.fromDate(time),
    };
  }

  factory Income.fromMap(Map<String, dynamic> map, String documentId) {
    return Income(
      id: documentId,
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      time: (map['time'] as Timestamp).toDate(),
    );
  }
}
