import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════════════════════
//  PALETTE
// ════════════════════════════════════════════════════════════
class C {
  static const cream      = Color(0xFFFDF8F2);
  static const cardWhite  = Color(0xFFFFFFFF);
  static const softGray   = Color(0xFFF2EFE9);
  static const mango      = Color(0xFFFF6B35);
  static const mangoLight = Color(0xFFFF8C55);
  static const sage       = Color(0xFF52B788);
  static const rose       = Color(0xFFE05780);
  static const ink        = Color(0xFF1A1207);
  static const subtext    = Color(0xFF7A6E63);
  static const muted      = Color(0xFFBBB1A5);
}

// ════════════════════════════════════════════════════════════
//  CATEGORIES
// ════════════════════════════════════════════════════════════
class Cat {
  final String label, short;
  final IconData icon;
  final Color color, bg;
  const Cat(this.label, this.short, this.icon, this.color, this.bg);
}

const cats = [
  Cat('General',   'General',   Icons.home_rounded,           Color(0xFF7B61FF), Color(0xFFF0EEFF)),
  Cat('Utilities', 'Utility',   Icons.bolt_rounded,           Color(0xFFF4A261), Color(0xFFFFF3E8)),
  Cat('Groceries', 'Grocery',   Icons.shopping_bag_rounded,   Color(0xFF52B788), Color(0xFFEBF7F1)),
  Cat('Internet',  'Internet',  Icons.wifi_rounded,           Color(0xFF3A86FF), Color(0xFFEBF3FF)),
  Cat('Food',      'Food',      Icons.restaurant_rounded,     Color(0xFFE05780), Color(0xFFFFEBF1)),
  Cat('Transport', 'Transport', Icons.directions_bus_rounded, Color(0xFF8338EC), Color(0xFFF3EBFF)),
];

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

  Map<String, dynamic> toMap() => {
    'id':           id,
    'title':        title,
    'paidBy':       paidBy,
    'amount':       amount,
    'date':         date.toIso8601String(),
    'catIndex':     cats.indexWhere((c) => c.label == cat.label),
    'isSettlement': isSettlement,
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id:           m['id'] as String,
    title:        m['title'] as String,
    paidBy:       m['paidBy'] as String,
    amount:       (m['amount'] as num).toDouble(),
    date:         DateTime.parse(m['date'] as String),
    cat:          cats[(m['catIndex'] as int).clamp(0, cats.length - 1)],
    isSettlement: m['isSettlement'] as bool? ?? false,
  );
}

// ════════════════════════════════════════════════════════════
//  STATE
// ════════════════════════════════════════════════════════════
class ExpenseState extends ChangeNotifier {
  static const _kExpenses     = 'sharedspace_expenses_v1';
  static const _kMyName       = 'sharedspace_my_name';
  static const _kRoommateName = 'sharedspace_roommate_name';

  String myName       = 'Me';
  String roommateName = 'Roommate';

  final List<Expense> _list = [];

  List<Expense> get expenses   => List.unmodifiable(_list);
  double get total             => _list.fold(0, (s, e) => s + e.amount);
  double get myShare           => total / 2;
  double get paidByMe          => _list.where((e) => e.paidBy == 'Me').fold(0, (s, e) => s + e.amount);
  double get paidByThem        => total - paidByMe;
  double get balance           => paidByMe - myShare;
  bool   get theyOweMe         => balance >= 0;
  double get balanceAmount     => balance.abs();
  bool   get isSettled         => balance == 0;

  String get balanceLabel =>
  theyOweMe ? '$roommateName owes you' : 'You owe $roommateName';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    myName       = prefs.getString(_kMyName)       ?? 'Me';
    roommateName = prefs.getString(_kRoommateName) ?? 'Roommate';

    final raw = prefs.getString(_kExpenses);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _list.clear();
        _list.addAll(decoded.map(
          (m) => Expense.fromMap(m as Map<String, dynamic>),
        ));
      } catch (_) {
        _seedDefaults();
      }
    } else {
      _seedDefaults();
    }
  }

  void _seedDefaults() {
    _list.clear();
    _list.addAll([
      Expense(id: '1', title: 'Electricity Bill', amount: 3500, paidBy: 'Me',
              date: DateTime.now().subtract(const Duration(days: 2)), cat: cats[1]),
              Expense(id: '2', title: 'Hostel Groceries', amount: 1200, paidBy: 'Roommate',
                      date: DateTime.now().subtract(const Duration(days: 1)), cat: cats[2]),
                      Expense(id: '3', title: 'Internet Plan', amount: 800, paidBy: 'Me',
                              date: DateTime.now(), cat: cats[3]),
    ]);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kExpenses, jsonEncode(_list.map((e) => e.toMap()).toList())),
      prefs.setString(_kMyName, myName),
      prefs.setString(_kRoommateName, roommateName),
    ]);
  }

  void add(String title, double amount, String paidBy, Cat cat,
           {bool isSettlement = false}) {
    _list.insert(0, Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, amount: amount, paidBy: paidBy,
      date: DateTime.now(), cat: cat, isSettlement: isSettlement,
    ));
    _persist();
    notifyListeners();
  }

  void update(String id, String title, double amount, String paidBy, Cat cat) {
    final idx = _list.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final old = _list[idx];
    _list[idx] = Expense(
      id: old.id, title: title, amount: amount, paidBy: paidBy,
      date: old.date, cat: cat, isSettlement: old.isSettlement,
    );
    _persist();
    notifyListeners();
  }

  ({Expense expense, int index}) removeById(String id) {
    final idx = _list.indexWhere((e) => e.id == id);
    final removed = _list[idx];
    _list.removeAt(idx);
    _persist();
    notifyListeners();
    return (expense: removed, index: idx);
  }

  void restoreAt(Expense expense, int index) {
    final clampedIdx = index.clamp(0, _list.length);
    _list.insert(clampedIdx, expense);
    _persist();
    notifyListeners();
  }

  void settleUp() {
    if (isSettled) return;
    final payer = theyOweMe ? 'Roommate' : 'Me';
    add('Settlement Payment', balanceAmount, payer, cats[0], isSettlement: true);
  }

  void renameMe(String name) {
    myName = name.trim().isEmpty ? 'Me' : name.trim();
    _persist();
    notifyListeners();
  }

  void renameRoommate(String name) {
    roommateName = name.trim().isEmpty ? 'Roommate' : name.trim();
    _persist();
    notifyListeners();
  }

  List<Object> get groupedItems {
    if (_list.isEmpty) return [];
    final now            = DateTime.now();
    final todayStart     = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    String bucket(DateTime d) {
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(todayStart))     return 'Today';
      if (!day.isBefore(yesterdayStart)) return 'Yesterday';
      return 'Earlier';
    }

    final result = <Object>[];
    String? lastHeader;
    for (final e in _list) {
      final header = bucket(e.date);
      if (header != lastHeader) { result.add(header); lastHeader = header; }
      result.add(e);
    }
    return result;
  }
}
