import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../models/day_record_model.dart';
import '../models/income_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Set allowance for a day
  Future<void> setDailyAllowance(
    String dateId,
    DateTime date,
    double allowance,
  ) async {
    DocumentReference dayRef = _db.collection('days').doc(dateId);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(dayRef);
      if (!snapshot.exists) {
        transaction.set(dayRef, {
          'date': Timestamp.fromDate(date),
          'allowance': allowance,
          'totalSpent': 0.0,
          'remaining': allowance,
        });
      } else {
        double currentSpent =
            (snapshot.data() as Map<String, dynamic>)['totalSpent'] ?? 0.0;
        transaction.update(dayRef, {
          'allowance': allowance,
          'remaining': allowance - currentSpent,
        });
      }
    });
  }

  // Add an expense
  Future<void> addExpense(String dateId, Expense expense) async {
    DocumentReference dayRef = _db.collection('days').doc(dateId);
    CollectionReference expensesRef = dayRef.collection('expenses');

    await _db.runTransaction((transaction) async {
      DocumentSnapshot daySnapshot = await transaction.get(dayRef);
      if (!daySnapshot.exists) {
        throw Exception("El día no ha sido inicializado con un monto.");
      }

      // Update day totals
      double currentSpent =
          (daySnapshot.data() as Map<String, dynamic>)['totalSpent'] ?? 0.0;
      double allowance =
          (daySnapshot.data() as Map<String, dynamic>)['allowance'] ?? 0.0;

      double newSpent = currentSpent + expense.amount;
      double newRemaining = allowance - newSpent;

      if (newRemaining < 0) {
        throw Exception(
          "Saldo insuficiente. Solo te quedan S/. ${allowance - currentSpent}",
        );
      }

      // Add expense to subcollection ONLY if it has enough balance
      DocumentReference newExpenseRef = expensesRef.doc();
      transaction.set(newExpenseRef, expense.toMap());

      transaction.update(dayRef, {
        'totalSpent': newSpent,
        'remaining': newRemaining,
      });
    });
  }

  // Add an income (top-up)
  Future<void> addIncome(String dateId, Income income) async {
    DocumentReference dayRef = _db.collection('days').doc(dateId);
    CollectionReference incomesRef = dayRef.collection('incomes');

    await _db.runTransaction((transaction) async {
      DocumentSnapshot daySnapshot = await transaction.get(dayRef);
      if (!daySnapshot.exists) {
        throw Exception("El día no ha sido inicializado con un monto.");
      }

      // Update day totals
      double currentAllowance =
          (daySnapshot.data() as Map<String, dynamic>)['allowance'] ?? 0.0;
      double currentRemaining =
          (daySnapshot.data() as Map<String, dynamic>)['remaining'] ?? 0.0;

      double newAllowance = currentAllowance + income.amount;
      double newRemaining = currentRemaining + income.amount;

      // Add income to subcollection
      DocumentReference newIncomeRef = incomesRef.doc();
      transaction.set(newIncomeRef, income.toMap());

      transaction.update(dayRef, {
        'allowance': newAllowance,
        'remaining': newRemaining,
      });
    });
  }

  // Get stream of current day
  Stream<DayRecord?> streamDay(String dateId) {
    return _db.collection('days').doc(dateId).snapshots().map((snap) {
      if (snap.exists) {
        return DayRecord.fromMap(snap.data() as Map<String, dynamic>, snap.id);
      }
      return null;
    });
  }

  // Get stream of expenses for a day
  Stream<List<Expense>> streamExpenses(String dateId) {
    return _db
        .collection('days')
        .doc(dateId)
        .collection('expenses')
        .orderBy('time', descending: true)
        .snapshots()
        .map(
          (list) => list.docs
              .map((doc) => Expense.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
