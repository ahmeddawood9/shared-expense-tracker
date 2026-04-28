import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'models.dart';
import 'expense_state.dart';
import 'widgets.dart';

// ════════════════════════════════════════════════════════════
//  DASHBOARD
// ════════════════════════════════════════════════════════════
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ExpenseState>();
    final items = s.groupedItems;

    return Scaffold(
      backgroundColor: C.cream,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: Header(state: s)),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        BalanceCard(state: s),
                        const SizedBox(height: 12),
                        SplitCard(state: s),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -16),
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
                        Pill('${s.expenses.length} items', C.mango),
                      ],
                    ),
                  ),
                ),
              ),
              if (s.expenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Transform.translate(
                    offset: const Offset(0, -40),
                    child: const EmptyState(),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final item = items[i];
                    if (item is String) {
                      return Transform.translate(
                        offset: const Offset(0, -16),
                        child: DateHeader(label: item),
                      );
                    }
                    final expense = item as Expense;
                    final isLast = i == items.length - 1;
                    return Transform.translate(
                      offset: const Offset(0, -16),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          isLast ? 110 : 10,
                        ),
                        child: ExpenseTile(
                          expense: expense,
                          onDismissed: (e) => _onDismiss(ctx, e),
                        ),
                      ),
                    );
                  }, childCount: items.length),
                ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: AddBtn(
              onTap: () {
                HapticFeedback.lightImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddExpenseSheet(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onDismiss(BuildContext context, Expense expense) {
    HapticFeedback.lightImpact();
    final state = context.read<ExpenseState>();
    final record = state.removeById(expense.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${expense.title}" removed'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              HapticFeedback.lightImpact();
              state.restoreAt(record.expense, record.index);
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }
}

// ════════════════════════════════════════════════════════════
//  HEADER
// ════════════════════════════════════════════════════════════
class Header extends StatelessWidget {
  final ExpenseState state;
  const Header({super.key, required this.state});

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
                            C.roomName,
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
                        const Avatar('Me', Colors.white, C.mango),
                        Positioned(
                          left: 28,
                          child: Avatar(
                            'R',
                            Colors.white.withOpacity(0.7),
                            Colors.white.withOpacity(0.54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                    HeaderStat(
                    'Total Spent',
                    '${C.currency} ${state.total.toStringAsFixed(0)}',
                  ),
                  _vDiv(),
                  HeaderStat(
                    'Your Share',
                    '${C.currency} ${state.myShare.toStringAsFixed(0)}',
                  ),
                  _vDiv(),
                  HeaderStat('Count', '${state.expenses.length} bills'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDiv() => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.white24,
  );
}

class Avatar extends StatelessWidget {
  final String label;
  final Color bg, textColor;
  const Avatar(this.label, this.bg, this.textColor, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: bg,
      border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
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

class HeaderStat extends StatelessWidget {
  final String label, value;
  const HeaderStat(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: Colors.white.withOpacity(0.60),
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

// ════════════════════════════════════════════════════════════
//  BALANCE CARD
// ════════════════════════════════════════════════════════════
class BalanceCard extends StatelessWidget {
  final ExpenseState state;
  const BalanceCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pos = state.theyOweMe;
    final accent = pos ? C.sage : C.rose;
    final bgCircle = pos ? const Color(0xFFEDF7F2) : const Color(0xFFFFF0F4);

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
                  child: AnimAmt(
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
                if (!state.isSettled)
                  GestureDetector(
                    onTap: () => _showSettleSheet(context, state),
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
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: C.sage.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration_rounded,
                          size: 15,
                          color: C.sage,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'All settled! 🎉',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: C.sage,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bgCircle),
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

  void _showSettleSheet(BuildContext context, ExpenseState state) {
    HapticFeedback.lightImpact();
    final debtor = state.theyOweMe ? 'roommate' : 'you';
    final creditor = state.theyOweMe ? 'you' : 'your roommate';
    final amount = state.balanceAmount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: C.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: C.muted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: C.sage.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handshake_outlined,
                color: C.sage,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Record Settlement?',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: C.ink,
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: C.subtext,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Record a payment of '),
                  TextSpan(
                    text: '${C.currency} ${amount.toStringAsFixed(0)}',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: C.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' paid by $debtor to $creditor?\nThis will bring the balance to ',
                  ),
                  TextSpan(
                    text: '${C.currency} 0',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: C.sage,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: C.muted.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: C.subtext,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.sage,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.read<ExpenseState>().settleUp();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Confirm & Settle',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SPLIT CARD
// ════════════════════════════════════════════════════════════
class SplitCard extends StatelessWidget {
  final ExpenseState state;
  const SplitCard({super.key, required this.state});

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
              Flexible(child: SplitLbl('You', state.paidByMe, C.mango)),
              const SizedBox(width: 10),
              Flexible(
                child: SplitLbl(
                  'Roommate',
                  state.paidByThem,
                  C.rose,
                  right: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SplitLbl extends StatelessWidget {
  final String name;
  final double amount;
  final Color color;
  final bool right;
  const SplitLbl(this.name, this.amount, this.color, {super.key, this.right = false});
  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
    final text = Expanded(
      child: Column(
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
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${C.currency} ${amount.toStringAsFixed(0)}',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: C.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    return right
        ? Row(children: [text, const SizedBox(width: 6), dot])
        : Row(children: [dot, const SizedBox(width: 6), text]);
  }
}

// ════════════════════════════════════════════════════════════
//  EXPENSE TILE
// ════════════════════════════════════════════════════════════
class ExpenseTile extends StatefulWidget {
  final Expense expense;
  final void Function(Expense) onDismissed;
  const ExpenseTile({super.key, required this.expense, required this.onDismissed});

  @override
  State<ExpenseTile> createState() => _ExpenseTileState();
}

class _ExpenseTileState extends State<ExpenseTile> with SingleTickerProviderStateMixin {
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
    final diff = DateTime.now().difference(e.date).inDays;
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
          onDismissed: (_) => widget.onDismissed(e),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 22),
            decoration: BoxDecoration(
              color: C.rose.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: C.rose,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  'Delete',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: C.rose,
                  ),
                ),
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: e.isSettlement ? C.sage.withOpacity(0.05) : C.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: e.isSettlement
                  ? Border.all(color: C.sage.withOpacity(0.25), width: 1)
                  : null,
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
                    color: e.isSettlement ? C.sage.withOpacity(0.1) : e.cat.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    e.isSettlement ? Icons.handshake_outlined : e.cat.icon,
                    color: e.isSettlement ? C.sage : e.cat.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.title,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: C.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (e.isSettlement)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: C.sage.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SETTLED',
                                style: GoogleFonts.nunito(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: C.sage,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
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
                          Flexible(
                            child: Text(
                              when,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: C.muted,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${C.currency} ${e.amount.toStringAsFixed(0)}',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: C.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${C.currency} ${(e.amount / 2).toStringAsFixed(0)}/ea',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: C.muted,
                          fontWeight: FontWeight.w600,
                        ),
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

// ════════════════════════════════════════════════════════════
//  ADD SHEET
// ════════════════════════════════════════════════════════════
class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});
  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
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
                  CustomField(
                    ctrl: _titleCtrl,
                    label: 'Description',
                    hint: 'e.g. Electricity Bill',
                  ),
                  const SizedBox(height: 12),
                  CustomField(
                    ctrl: _amountCtrl,
                    label: 'Amount',
                    hint: '0',
                    prefix: '${C.currency} ',
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
                      PayerBtn(
                        '🙋  I paid',
                        _payer == 'Me',
                        C.mango,
                        () => setState(() => _payer = 'Me'),
                      ),
                      const SizedBox(width: 10),
                      PayerBtn(
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _save();
                      },
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

// ════════════════════════════════════════════════════════════
//  PAYER BUTTON
// ════════════════════════════════════════════════════════════
class PayerBtn extends StatelessWidget {
  final String label;
  final bool sel;
  final Color color;
  final VoidCallback onTap;
  const PayerBtn(this.label, this.sel, this.color, this.onTap, {super.key});
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
