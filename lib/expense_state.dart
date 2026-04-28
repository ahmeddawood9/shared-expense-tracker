import 'package:flutter/material.dart';
import 'constants.dart';
import 'models.dart';

// ════════════════════════════════════════════════════════════
//  STATE
// ════════════════════════════════════════════════════════════
class ExpenseState extends ChangeNotifier {
  final List<Expense> _list = [
    Expense(
      id: '1',
      title: 'Electricity Bill',
      amount: 3500,
      paidBy: 'Me',
      date: DateTime.now().subtract(const Duration(days: 2)),
      cat: cats[1],
    ),
    Expense(
      id: '2',
      title: 'Hostel Groceries',
      amount: 1200,
      paidBy: 'Roommate',
      date: DateTime.now().subtract(const Duration(days: 1)),
      cat: cats[2],
    ),
    Expense(
      id: '3',
      title: 'Internet Plan',
      amount: 800,
      paidBy: 'Me',
      date: DateTime.now(),
      cat: cats[3],
    ),
  ];

  List<Expense> get expenses => List.unmodifiable(_list);
  double get total => _list.fold(0, (s, e) => s + e.amount);
  double get myShare => total / 2;
  double get paidByMe =>
      _list.where((e) => e.paidBy == 'Me').fold(0, (s, e) => s + e.amount);
  double get paidByThem => total - paidByMe;
  double get balance => paidByMe - myShare;
  bool get theyOweMe => balance >= 0;
  double get balanceAmount => balance.abs();
  String get balanceLabel =>
      theyOweMe ? 'Roommate owes you' : 'You owe roommate';
  bool get isSettled => balance == 0;

  void add(
    String title,
    double amount,
    String paidBy,
    Cat cat, {
    bool isSettlement = false,
  }) {
    _list.insert(
      0,
      Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        paidBy: paidBy,
        date: DateTime.now(),
        cat: cat,
        isSettlement: isSettlement,
      ),
    );
    notifyListeners();
  }

  ({Expense expense, int index}) removeById(String id) {
    final idx = _list.indexWhere((e) => e.id == id);
    final removed = _list[idx];
    _list.removeAt(idx);
    notifyListeners();
    return (expense: removed, index: idx);
  }

  void restoreAt(Expense expense, int index) {
    final clampedIdx = index.clamp(0, _list.length);
    _list.insert(clampedIdx, expense);
    notifyListeners();
  }

  void settleUp() {
    if (isSettled) return;
    final payer = theyOweMe ? 'Roommate' : 'Me';
    add(
      'Settlement Payment',
      balanceAmount,
      payer,
      cats[0],
      isSettlement: true,
    );
  }

  List<Object> get groupedItems {
    if (_list.isEmpty) return [];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    String bucket(DateTime d) {
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(todayStart)) return 'Today';
      if (!day.isBefore(yesterdayStart)) return 'Yesterday';
      return 'Earlier';
    }

    final result = <Object>[];
    String? lastHeader;

    for (final e in _list) {
      final header = bucket(e.date);
      if (header != lastHeader) {
        result.add(header);
        lastHeader = header;
      }
      result.add(e);
    }
    return result;
  }
}
