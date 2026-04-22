import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ExpenseState(),
      child: const SharedSpaceApp(),
    ),
  );
}

// ─── PALETTE ────────────────────────────────────────────────────────────────
class C {
  static const cream = Color(0xFFFDF8F2);
  static const cardWhite = Color(0xFFFFFFFF);
  static const softGray = Color(0xFFF2EFE9);
  static const mango = Color(0xFFFF6B35);
  static const mangoLight = Color(0xFFFF8C55);
  static const sage = Color(0xFF52B788);
  static const rose = Color(0xFFE05780);
  static const ink = Color(0xFF1A1207);
  static const subtext = Color(0xFF7A6E63);
  static const muted = Color(0xFFBBB1A5);
}

// ─── CATEGORIES ─────────────────────────────────────────────────────────────
class Cat {
  final String label, short;
  final IconData icon;
  final Color color, bg;
  const Cat(this.label, this.short, this.icon, this.color, this.bg);
}

const cats = [
  Cat(
    'General',
    'General',
    Icons.home_rounded,
    Color(0xFF7B61FF),
    Color(0xFFF0EEFF),
  ),
  Cat(
    'Utilities',
    'Utility',
    Icons.bolt_rounded,
    Color(0xFFF4A261),
    Color(0xFFFFF3E8),
  ),
  Cat(
    'Groceries',
    'Grocery',
    Icons.shopping_bag_rounded,
    Color(0xFF52B788),
    Color(0xFFEBF7F1),
  ),
  Cat(
    'Internet',
    'Internet',
    Icons.wifi_rounded,
    Color(0xFF3A86FF),
    Color(0xFFEBF3FF),
  ),
  Cat(
    'Food',
    'Food',
    Icons.restaurant_rounded,
    Color(0xFFE05780),
    Color(0xFFFFEBF1),
  ),
  Cat(
    'Transport',
    'Transport',
    Icons.directions_bus_rounded,
    Color(0xFF8338EC),
    Color(0xFFF3EBFF),
  ),
];

// ─── MODEL ──────────────────────────────────────────────────────────────────
class Expense {
  final String id, title, paidBy;
  final double amount;
  final DateTime date;
  final Cat cat;
  Expense({
    required this.id,
    required this.title,
    required this.paidBy,
    required this.amount,
    required this.date,
    required this.cat,
  });
}

// ─── STATE ──────────────────────────────────────────────────────────────────
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

  void add(String title, double amount, String paidBy, Cat cat) {
    _list.insert(
      0,
      Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        paidBy: paidBy,
        date: DateTime.now(),
        cat: cat,
      ),
    );
    notifyListeners();
  }

  void remove(String id) {
    _list.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

// ─── APP ────────────────────────────────────────────────────────────────────
class SharedSpaceApp extends StatelessWidget {
  const SharedSpaceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SharedSpace',
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: C.cream,
      colorScheme: const ColorScheme.light(
        primary: C.mango,
        secondary: C.sage,
        surface: C.cardWhite,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme),
      useMaterial3: true,
    ),
    home: const DashboardScreen(),
  );
}

// ─── DASHBOARD ──────────────────────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ExpenseState>();
    return Scaffold(
      backgroundColor: C.cream,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Header(state: s)),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _BalanceCard(state: s),
                        const SizedBox(height: 12),
                        _SplitCard(state: s),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions',
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: C.ink,
                          ),
                        ),
                        _Pill('${s.expenses.length} items', C.mango),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Transform.translate(
                    offset: const Offset(0, -20),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        i == s.expenses.length - 1 ? 110 : 10,
                      ),
                      child: _Tile(expense: s.expenses[i]),
                    ),
                  ),
                  childCount: s.expenses.length,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: _AddBtn(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const _AddSheet(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HEADER ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final ExpenseState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.mangoLight, C.mango],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.home_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Room 42',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SharedSpace',
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 68,
                    child: Stack(
                      children: [
                        _Av('Me', Colors.white, C.mango),
                        Positioned(
                          left: 28,
                          child: _Av('R', Colors.white70, Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _HStat(
                    'Total Spent',
                    'Rs. ${state.total.toStringAsFixed(0)}',
                  ),
                  _vDivider(),
                  _HStat(
                    'Your Share',
                    'Rs. ${state.myShare.toStringAsFixed(0)}',
                  ),
                  _vDivider(),
                  _HStat('Count', '${state.expenses.length} bills'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.white24,
  );
}

class _Av extends StatelessWidget {
  final String label;
  final Color bg, textColor;
  const _Av(this.label, this.bg, this.textColor);
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: bg,
      border: Border.all(color: Colors.white60, width: 2),
    ),
    child: Center(
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    ),
  );
}

class _HStat extends StatelessWidget {
  final String label, value;
  const _HStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: Colors.white60,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: GoogleFonts.nunito(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

// ─── BALANCE CARD ────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final ExpenseState state;
  const _BalanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final pos = state.theyOweMe;
    final accent = pos ? C.sage : C.rose;
    final bg = pos ? const Color(0xFFEDF7F2) : const Color(0xFFFFF0F4);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.cardWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.balanceLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: C.subtext,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _AnimAmt(
                    amount: state.balanceAmount,
                    style: GoogleFonts.nunito(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 15,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Settle Up',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Icon(
              pos ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: accent,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SPLIT CARD ──────────────────────────────────────────────────────────────
class _SplitCard extends StatelessWidget {
  final ExpenseState state;
  const _SplitCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final ratio = state.total == 0
        ? 0.5
        : (state.paidByMe / state.total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: C.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Split',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: C.ink,
                ),
              ),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}% · ${((1 - ratio) * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: C.subtext,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Stack(
                children: [
                  Container(height: 8, color: C.rose.withOpacity(0.18)),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [C.mango, C.sage],
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SplitLbl('You', state.paidByMe, C.mango),
              _SplitLbl('Roommate', state.paidByThem, C.rose, right: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitLbl extends StatelessWidget {
  final String name;
  final double amount;
  final Color color;
  final bool right;
  const _SplitLbl(this.name, this.amount, this.color, {this.right = false});
  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
    final text = Column(
      crossAxisAlignment: right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: C.subtext,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(0)}',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: C.ink,
          ),
        ),
      ],
    );
    return right
        ? Row(children: [text, const SizedBox(width: 6), dot])
        : Row(children: [dot, const SizedBox(width: 6), text]);
  }
}

// ─── PILL ────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

// ─── EXPENSE TILE ────────────────────────────────────────────────────────────
class _Tile extends StatefulWidget {
  final Expense expense;
  const _Tile({required this.expense});
  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(milliseconds: 320),
    vsync: this,
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;
    final iPaid = e.paidBy == 'Me';

    // Fixed absolute calendar date calculation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
    final diff = today.difference(expenseDate).inDays;
    final when = diff == 0
        ? 'Today'
        : diff == 1
        ? 'Yesterday'
        : '${diff}d ago';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Dismissible(
          key: Key(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: C.rose.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: C.rose),
          ),
          onDismissed: (_) => context.read<ExpenseState>().remove(e.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: C.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: e.cat.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(e.cat.icon, color: e.cat.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: C.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: iPaid
                                  ? C.mango.withOpacity(0.1)
                                  : C.softGray,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              iPaid ? '🙋 You' : '🧑 Roommate',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: iPaid ? C.mango : C.subtext,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            when,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: C.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${e.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: C.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${(e.amount / 2).toStringAsFixed(0)}/ea',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        color: C.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ANIMATED AMOUNT ─────────────────────────────────────────────────────────
class _AnimAmt extends StatefulWidget {
  final double amount;
  final TextStyle style;
  const _AnimAmt({required this.amount, required this.style});
  @override
  State<_AnimAmt> createState() => _AnimAmtState();
}

class _AnimAmtState extends State<_AnimAmt>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  double _prev = 0;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _a = Tween<double>(
      begin: 0,
      end: widget.amount,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void didUpdateWidget(_AnimAmt old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount) {
      _prev = old.amount;
      _a = Tween<double>(
        begin: _prev,
        end: widget.amount,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) =>
        Text('Rs. ${_a.value.toStringAsFixed(0)}', style: widget.style),
  );
}

// ─── ADD BUTTON ──────────────────────────────────────────────────────────────
class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [C.mangoLight, C.mango]),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: C.mango.withOpacity(0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 7),
          Text(
            'Add Expense',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── ADD SHEET ───────────────────────────────────────────────────────────────
class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _payer = 'Me';
  Cat _cat = cats[0];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: C.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        // Ensures navigation bar doesn't clip the bottom
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: C.muted.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22, 10, 22, bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Expense',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: C.ink,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Category',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: C.subtext,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = cats[i];
                          final sel = c == _cat;
                          return GestureDetector(
                            onTap: () => setState(() => _cat = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 60,
                              decoration: BoxDecoration(
                                color: sel ? c.bg : C.softGray,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: sel
                                      ? c.color.withOpacity(0.45)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    c.icon,
                                    color: sel ? c.color : C.muted,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.short.length > 6
                                        ? '${c.short.substring(0, 5)}.'
                                        : c.short,
                                    style: GoogleFonts.nunito(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? c.color : C.muted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      ctrl: _titleCtrl,
                      label: 'Description',
                      hint: 'e.g. Electricity Bill',
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      ctrl: _amountCtrl,
                      label: 'Amount',
                      hint: '0',
                      prefix: 'Rs. ',
                      kb: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Who paid?',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: C.subtext,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _PayBtn(
                          '🙋  I paid',
                          _payer == 'Me',
                          C.mango,
                          () => setState(() => _payer = 'Me'),
                        ),
                        const SizedBox(width: 10),
                        _PayBtn(
                          '🧑  Roommate paid',
                          _payer == 'Roommate',
                          C.rose,
                          () => setState(() => _payer = 'Roommate'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.mango,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _save,
                        child: Text(
                          'Save Expense',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) return;
    context.read<ExpenseState>().add(_titleCtrl.text, amt, _payer, _cat);
    Navigator.pop(context);
  }
}

// ─── TEXT FIELD ──────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final String? prefix;
  final TextInputType? kb;
  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.prefix,
    this.kb,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: kb,
    style: GoogleFonts.nunito(
      fontSize: 15,
      color: C.ink,
      fontWeight: FontWeight.w700,
    ),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      labelStyle: GoogleFonts.nunito(
        fontSize: 13,
        color: C.subtext,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.nunito(color: C.muted),
      prefixStyle: GoogleFonts.nunito(
        fontSize: 15,
        color: C.subtext,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: C.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: C.mango, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
    ),
  );
}

// ─── PAYER BUTTON ────────────────────────────────────────────────────────────
class _PayBtn extends StatelessWidget {
  final String label;
  final bool sel;
  final Color color;
  final VoidCallback onTap;
  const _PayBtn(this.label, this.sel, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 46,
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.1) : C.softGray,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: sel ? color.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: sel ? color : C.subtext,
            ),
          ),
        ),
      ),
    ),
  );
}
