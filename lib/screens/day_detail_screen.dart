import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
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
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay gastos registrados.'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final expense = Expense.fromMap(data, docs[index].id);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.errorContainer,
                        child: Icon(
                          Icons.money_off,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      title: Text(
                        expense.description,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        DateFormat('hh:mm a').format(expense.time),
                      ),
                      trailing: Text(
                        '- S/. ${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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
