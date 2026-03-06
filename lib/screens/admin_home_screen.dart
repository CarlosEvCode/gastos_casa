import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/day_record_model.dart';
import '../screens/statistics_screen.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'history_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirestoreService _db = FirestoreService();
  final AuthService _auth = AuthService();

  String get todayId {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void _showSetAllowanceDialog() {
    double allowance = 0.0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Monto recibido hoy'),
          content: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              allowance = double.tryParse(val) ?? 0.0;
            },
            decoration: const InputDecoration(
              hintText: "Ej. 20.00",
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _db.setDailyAllowance(todayId, DateTime.now(), allowance);
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, DayRecord dayRecord) {
    if (dayRecord.allowance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Establece el monto recibido primero.')),
      );
      return;
    }

    String description = '';
    double amount = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo Gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: "Descripción (ej. Pasaje)",
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => description = val,
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: "Monto (ej. 5.00)",
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => amount = double.tryParse(val) ?? 0.0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (description.isNotEmpty && amount > 0) {
                  Expense expense = Expense(
                    id: '', // Firestore genera el ID
                    description: description,
                    amount: amount,
                    time: DateTime.now(),
                  );
                  try {
                    await _db.addExpense(todayId, expense);
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _showAddIncomeDialog(BuildContext context, DayRecord dayRecord) {
    if (dayRecord.allowance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Establece el monto recibido primero.')),
      );
      return;
    }

    String description = 'Recarga / Aumento';
    double amount = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Saldo (Recarga)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: "Motivo (ej. Para cena)",
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => description = val,
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: "Monto (ej. 10.00)",
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => amount = double.tryParse(val) ?? 0.0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (description.isNotEmpty && amount > 0) {
                  Income income = Income(
                    id: '', // Firestore genera el ID
                    description: description,
                    amount: amount,
                    time: DateTime.now(),
                  );
                  try {
                    await _db.addIncome(todayId, income);
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Agregar Saldo'),
            ),
          ],
        );
      },
    );
  }

  void _showTakeFromSavingsDialog(BuildContext context, DayRecord dayRecord) {
    final titleController = TextEditingController(text: 'Retiro de Ahorros');
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tomar de Ahorros'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Motivo del retiro',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto a retirar (S/.)',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;

                final income = Income(
                  id: '',
                  description: titleController.text, // "Retiro de ahorros: ..."
                  amount: amount,
                  time: DateTime.now(),
                );

                try {
                  await _db.takeFromSavings(dayRecord.id, income);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Retirar'),
            ),
          ],
        );
      },
    );
  }

  void _showTopUpOptionsBottomSheet(BuildContext context, DayRecord dayRecord) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Elige cómo recargar dinero',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.attach_money)),
                  title: const Text('Recarga Externa'),
                  subtitle: const Text('Dinero extra recibido hoy'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddIncomeDialog(context, dayRecord);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.savings_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: const Text('Tomar de Ahorros'),
                  subtitle: const Text(
                    'Retirar del pozo de los días sobrantes',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showTakeFromSavingsDialog(context, dayRecord);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Registro (Tú)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadísticas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
            tooltip: 'Ver Historial',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DayRecord?>(
        stream: _db.streamDay(todayId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          DayRecord? dayRecord = snapshot.data;
          bool hasAllowance = dayRecord != null && dayRecord.allowance > 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hoy: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Monto recibido: S/. ${dayRecord?.allowance.toStringAsFixed(2) ?? "0.00"}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total gastado: S/. ${dayRecord?.totalSpent.toStringAsFixed(2) ?? "0.00"}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const Divider(height: 24),
                        Text(
                          'Sobrante del día',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'S/. ${dayRecord?.remaining.toStringAsFixed(2) ?? "0.00"}',
                          style: TextStyle(
                            fontSize: 32,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (!hasAllowance)
                  ElevatedButton(
                    onPressed: _showSetAllowanceDialog,
                    child: const Text('Registrar monto recibido hoy'),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Gastos de hoy:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: StreamBuilder<List<Expense>>(
                    stream: _db.streamExpenses(todayId),
                    builder: (context, expenseSnap) {
                      if (expenseSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      List<Expense> expenses = expenseSnap.data ?? [];
                      if (expenses.isEmpty) {
                        return const Center(
                          child: Text("No hay gastos registrados hoy."),
                        );
                      }
                      return ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          Expense exp = expenses[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              child: Icon(
                                Icons.money_off,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                            title: Text(
                              exp.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('HH:mm').format(exp.time),
                            ),
                            trailing: Text(
                              '- S/. ${exp.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (hasAllowance)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () => _showAddExpenseDialog(context, dayRecord),
                    icon: const Icon(Icons.money_off),
                    label: const Text(
                      'Agregar Gasto',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: StreamBuilder<DayRecord?>(
        stream: _db.streamDay(todayId),
        builder: (context, snapshot) {
          DayRecord? dayRecord = snapshot.data;
          bool hasAllowance = dayRecord != null && dayRecord.allowance > 0;
          if (!hasAllowance) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () => _showTopUpOptionsBottomSheet(context, dayRecord),
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
            tooltip: 'Recargar Saldo',
            child: const Icon(Icons.add_card),
          );
        },
      ),
    );
  }
}
