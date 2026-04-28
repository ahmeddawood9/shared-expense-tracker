import 'constants.dart';

// ════════════════════════════════════════════════════════════
//  MODEL
// ════════════════════════════════════════════════════════════
class Expense {
  final String id, title, paidBy;
  final double amount;
  final DateTime date;
  final Cat cat;
  final bool isSettlement;

  Expense({
    required this.id,
    required this.title,
    required this.paidBy,
    required this.amount,
    required this.date,
    required this.cat,
    this.isSettlement = false,
  });
}
