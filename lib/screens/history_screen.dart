import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/day_record_model.dart';
import 'day_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Días')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('days')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay historial todavía.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final dayRecord = DayRecord(
                id: doc.id,
                date: (data['date'] as Timestamp).toDate(),
                allowance: (data['allowance'] ?? 0.0).toDouble(),
                totalSpent: (data['totalSpent'] ?? 0.0).toDouble(),
                remaining: (data['remaining'] ?? 0.0).toDouble(),
              );

              // Only format if date matches yyyy-MM-dd the ID format
              final titleDate = doc.id;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DayDetailScreen(dayRecord: dayRecord),
                    ),
                  );
                },
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleDate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
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
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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
