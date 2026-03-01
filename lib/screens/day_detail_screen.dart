import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/day_record_model.dart';

class DayDetailScreen extends StatelessWidget {
  final DayRecord dayRecord;

  const DayDetailScreen({Key? key, required this.dayRecord}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalle: ${dayRecord.id}')),
      body: Column(
        children: [
          _buildSummaryCard(context),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Gastos del Día',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('days')
                  .doc(dayRecord.id)
                  .collection('expenses')
                  .snapshots(),
              builder: (context, expensesSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('days')
                      .doc(dayRecord.id)
                      .collection('incomes')
                      .snapshots(),
                  builder: (context, incomesSnapshot) {
                    if (expensesSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        incomesSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final expensesDocs = expensesSnapshot.data?.docs ?? [];
                    final incomesDocs = incomesSnapshot.data?.docs ?? [];

                    if (expensesDocs.isEmpty && incomesDocs.isEmpty) {
                      return const Center(
                        child: Text('No hay movimientos registrados.'),
                      );
                    }

                    List<Map<String, dynamic>> allItems = [];

                    for (var doc in expensesDocs) {
                      allItems.add({
                        'type': 'expense',
                        'data': Expense.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      });
                    }

                    for (var doc in incomesDocs) {
                      allItems.add({
                        'type': 'income',
                        'data': Income.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      });
                    }

                    allItems.sort((a, b) {
                      DateTime timeA = a['data'].time;
                      DateTime timeB = b['data'].time;
                      return timeB.compareTo(timeA);
                    });

                    return ListView.builder(
                      itemCount: allItems.length,
                      itemBuilder: (context, index) {
                        final item = allItems[index];
                        final isExpense = item['type'] == 'expense';
                        final dynamic data = item['data'];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isExpense
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.tertiaryContainer,
                            child: Icon(
                              isExpense ? Icons.money_off : Icons.add_card,
                              color: isExpense
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
                            ),
                          ),
                          title: Text(
                            data.description,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            DateFormat('hh:mm a').format(data.time),
                          ),
                          trailing: Text(
                            isExpense
                                ? '- S/. ${data.amount.toStringAsFixed(2)}'
                                : '+ S/. ${data.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isExpense
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryColumn(
              context,
              'Recibido',
              dayRecord.allowance,
              Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            _buildSummaryColumn(
              context,
              'Gastado',
              dayRecord.totalSpent,
              Theme.of(context).colorScheme.error,
            ),
            _buildSummaryColumn(
              context,
              'Sobró',
              dayRecord.remaining,
              Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'S/. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
