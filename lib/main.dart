import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    ChangeNotifierProvider(create: (_) => ExpenseState(), child: const SharedSpaceApp()),
  );
}

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

class Expense {
  final String id, title, paidBy;
  final double amount;
  final DateTime date;
  final Cat cat;
  final bool isSettlement;

  Expense({
    required this.id, required this.title, required this.paidBy,
    required this.amount, required this.date, required this.cat,
    this.isSettlement = false,
  });
}

class ExpenseState extends ChangeNotifier {
  String myName       = 'Me';
  String roommateName = 'Roommate';

  final List<Expense> _list = [
    Expense(id: '1', title: 'Electricity Bill', amount: 3500, paidBy: 'Me',
            date: DateTime.now().subtract(const Duration(days: 2)), cat: cats[1]),
    Expense(id: '2', title: 'Hostel Groceries', amount: 1200, paidBy: 'Roommate',
            date: DateTime.now().subtract(const Duration(days: 1)), cat: cats[2]),
    Expense(id: '3', title: 'Internet Plan', amount: 800, paidBy: 'Me',
            date: DateTime.now(), cat: cats[3]),
  ];

  List<Expense> get expenses   => List.unmodifiable(_list);
  double get total             => _list.fold(0, (s, e) => s + e.amount);
  double get myShare           => total / 2;
  double get paidByMe          => _list.where((e) => e.paidBy == 'Me').fold(0, (s, e) => s + e.amount);
  double get balance           => paidByMe - myShare;
  bool   get theyOweMe         => balance >= 0;
  double get balanceAmount     => balance.abs();
  bool   get isSettled         => balance == 0;

  String get balanceLabel => theyOweMe ? '$roommateName owes you' : 'You owe $roommateName';

  void add(String title, double amount, String paidBy, Cat cat, {bool isSettlement = false}) {
    _list.insert(0, Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, amount: amount, paidBy: paidBy,
      date: DateTime.now(), cat: cat, isSettlement: isSettlement,
    ));
    notifyListeners();
  }

  void removeById(String id) {
    _list.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void settleUp() {
    if (isSettled) return;
    final payer = theyOweMe ? 'Roommate' : 'Me';
    add('Settlement Payment', balanceAmount, payer, cats[0], isSettlement: true);
  }

  List<Object> get groupedItems {
    if (_list.isEmpty) return [];
    final result = <Object>[];
    result.add('All Transactions');
    result.addAll(_list);
    return result;
  }
}

class SharedSpaceApp extends StatelessWidget {
  const SharedSpaceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: C.mango),
    home: const DashboardScreen(),
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ExpenseState>();
    final items = s.groupedItems;
    return Scaffold(
      backgroundColor: C.cream,
      body: Stack(children: [
        CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _Header(state: s)),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  _BalanceCard(state: s),
                  const SizedBox(height: 12),
                  _SplitCard(state: s),
                ]),
              ),
            ),
          ),
          SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
            final item = items[i];
            if (item is String) return _DateHeader(label: item);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _Tile(expense: item as Expense),
            );
          }, childCount: items.length)),
        ]),
        Positioned(
          bottom: 24, left: 20, right: 20,
          child: _AddBtn(onTap: () => showModalBottomSheet(
            context: context, isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _ExpenseSheet(),
          )),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final ExpenseState state;
  const _Header({required this.state});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [C.mangoLight, C.mango]),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
    ),
    child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('SharedSpace', style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        Row(children: [
          _AvatarBadge(label: 'M', bg: Colors.white, textColor: C.mango),
          Transform.translate(offset: const Offset(-10, 0), child: _AvatarBadge(label: 'R', bg: Colors.white60, textColor: Colors.white)),
        ]),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        _HStat('Total Spent', 'Rs. ${state.total.toStringAsFixed(0)}'),
        const SizedBox(width: 20),
        _HStat('Your Share', 'Rs. ${state.myShare.toStringAsFixed(0)}'),
      ]),
    ])),
  );
}

class _HStat extends StatelessWidget {
  final String l, v;
  const _HStat(this.l, this.v);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: GoogleFonts.nunito(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w700)),
    Text(v, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
  ]);
}

class _AvatarBadge extends StatelessWidget {
  final String label; final Color bg, textColor;
  const _AvatarBadge({required this.label, required this.bg, required this.textColor});
  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
    child: Center(child: Text(label, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: textColor))),
  );
}

class _BalanceCard extends StatelessWidget {
  final ExpenseState state;
  const _BalanceCard({required this.state});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: C.cardWhite, borderRadius: BorderRadius.circular(24)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(state.balanceLabel, style: GoogleFonts.nunito(fontSize: 13, color: C.subtext, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Rs. ${state.balanceAmount.toStringAsFixed(0)}', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: C.ink)),
      ])),
      if (!state.isSettled) ElevatedButton(
        onPressed: () => state.settleUp(),
        style: ElevatedButton.styleFrom(backgroundColor: C.sage, foregroundColor: Colors.white),
        child: const Text('Settle Up'),
      ),
    ]),
  );
}

class _SplitCard extends StatelessWidget {
  final ExpenseState state;
  const _SplitCard({required this.state});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(color: C.softGray, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Split 50/50', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: C.subtext)),
      const Icon(Icons.people_alt_outlined, size: 18, color: C.muted),
    ]),
  );
}

class _Tile extends StatelessWidget {
  final Expense expense;
  const _Tile({required this.expense});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: C.cardWhite, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: expense.cat.bg, borderRadius: BorderRadius.circular(14)),
        child: Icon(expense.cat.icon, color: expense.cat.color, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(expense.title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: C.ink)),
        Text(expense.paidBy, style: GoogleFonts.nunito(fontSize: 11, color: C.muted, fontWeight: FontWeight.w600)),
      ])),
      Text('Rs. ${expense.amount.toStringAsFixed(0)}', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900, color: C.ink)),
    ]),
  );
}

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
    child: Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: C.subtext)),
  );
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(backgroundColor: C.mango, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56)),
    child: const Text('Add Expense'),
  );
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet();
  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _t = TextEditingController();
  final _a = TextEditingController();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: const BoxDecoration(color: C.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _t, decoration: const InputDecoration(labelText: 'Description')),
      TextField(controller: _a, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () {
        context.read<ExpenseState>().add(_t.text, double.parse(_a.text), 'Me', cats[0]);
        Navigator.pop(context);
      }, child: const Text('Save')),
    ]),
  );
}
