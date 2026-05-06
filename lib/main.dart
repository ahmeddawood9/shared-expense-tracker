import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models.dart';
import 'voice_controller.dart';

// ════════════════════════════════════════════════════════════
//  MAIN — async init so persistence and VUI load before first frame
// ════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final expenseState = ExpenseState();
  await expenseState.init();

  final voiceController = VoiceController(expenseState);
  await voiceController.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: expenseState),
        ChangeNotifierProvider.value(value: voiceController),
      ],
      child: const SharedSpaceApp(),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  APP
// ════════════════════════════════════════════════════════════
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
        primary: C.mango, secondary: C.sage, surface: C.cardWhite),
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: C.ink,
          actionTextColor: C.mango,
          contentTextStyle: GoogleFonts.nunito(
            color: Colors.white, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            behavior: SnackBarBehavior.floating,
            insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ),
    ),
    home: const DashboardScreen(),
  );
}

// ════════════════════════════════════════════════════════════
//  DASHBOARD
// ════════════════════════════════════════════════════════════
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s     = context.watch<ExpenseState>();
    final v     = context.watch<VoiceController>();
    final items = s.groupedItems;

    return Scaffold(
      backgroundColor: C.cream,
      body: Stack(children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(state: s)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(children: [
                  _BalanceCard(state: s),
                  const SizedBox(height: 12),
                  _SplitCard(state: s),
                  if (v.status != "Idle" || v.lastWords.isNotEmpty)
                    _VoiceStatusCard(v: v),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transactions', style: GoogleFonts.nunito(
                      fontSize: 17, fontWeight: FontWeight.w800, color: C.ink)),
                    _Pill('${s.expenses.length} items', C.mango),
                  ],
                ),
              ),
            ),

            if (s.expenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: const _EmptyState(),
              )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final item   = items[i];
                      final isLast = i == items.length - 1;
                      if (item is String) {
                        return _DateHeader(label: item);
                      }
                      final expense = item as Expense;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, isLast ? 110 : 10),
                        child: _Tile(
                          expense: expense,
                          onDismissed: (e) => _onDismiss(ctx, e),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
          ],
        ),

        // FAB Group
        Positioned(
          bottom: 24, left: 20, right: 20,
          child: Row(
            children: [
              Expanded(
                child: _AddBtn(onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const _ExpenseSheet(),
                  );
                }),
              ),
              const SizedBox(width: 12),
              _VoiceFAB(
                isListening: v.isListening,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  v.listen();
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _onDismiss(BuildContext context, Expense expense) {
    HapticFeedback.lightImpact();
    final state  = context.read<ExpenseState>();
    final record = state.removeById(expense.id);
    ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('"${expense.title}" removed'),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          HapticFeedback.lightImpact();
          state.restoreAt(record.expense, record.index);
        },
      ),
      duration: const Duration(seconds: 4),
    ));
  }
}

// ════════════════════════════════════════════════════════════
//  VOICE STATUS CARD
// ════════════════════════════════════════════════════════════
class _VoiceStatusCard extends StatelessWidget {
  final VoiceController v;
  const _VoiceStatusCard({required this.v});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.sage.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.sage.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.record_voice_over_rounded, size: 16, color: C.sage),
            const SizedBox(width: 8),
            Text(v.status, style: GoogleFonts.nunito(
              fontSize: 12, fontWeight: FontWeight.w800, color: C.sage)),
          ]),
          if (v.lastWords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${v.lastWords}"', style: GoogleFonts.nunito(
              fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: C.ink)),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  VOICE FAB
// ════════════════════════════════════════════════════════════
class _VoiceFAB extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;
  const _VoiceFAB({required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: isListening ? C.rose : C.sage,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isListening ? C.rose : C.sage).withValues(alpha: 0.3),
              blurRadius: isListening ? 20 : 10,
              spreadRadius: isListening ? 5 : 0,
            )
          ],
        ),
        child: Icon(
          isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  EMPTY STATE
// ════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: C.mango.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, size: 48, color: C.mango),
        ),
        const SizedBox(height: 24),
        Text('No expenses yet!', style: GoogleFonts.nunito(
          fontSize: 22, fontWeight: FontWeight.w900, color: C.ink),
          textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('Tap "Add Expense" or use Voice to log your first bill.\nKeeping track is caring! 🏠',
               style: GoogleFonts.nunito(fontSize: 14, color: C.subtext,
                                         fontWeight: FontWeight.w600, height: 1.5),
               textAlign: TextAlign.center),
               const SizedBox(height: 28),
               Icon(Icons.keyboard_arrow_down_rounded,
                    color: C.mango.withValues(alpha: 0.5), size: 32),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  DATE GROUP HEADER
// ════════════════════════════════════════════════════════════
class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    child: Row(children: [
      Text(label, style: GoogleFonts.nunito(
        fontSize: 12, fontWeight: FontWeight.w800,
        color: C.subtext, letterSpacing: 0.6)),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: C.muted.withValues(alpha: 0.35), thickness: 1)),
    ]),
  );
}

// ════════════════════════════════════════════════════════════
//  HEADER
// ════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final ExpenseState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.mangoLight, C.mango],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.home_rounded, color: Colors.white70, size: 14),
                  const SizedBox(width: 5),
                  Text('Room 42', style: GoogleFonts.nunito(
                    fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 2),
                Text('SharedSpace', style: GoogleFonts.nunito(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: Colors.white, height: 1.1)),
              ]),

              Row(children: [
                Tooltip(
                  message: 'Tap to rename',
                  child: GestureDetector(
                    onTap: () => _showRenameDialog(
                      context,
                      currentName: state.myName,
                      label: 'Your name',
                      onSave: (n) {
                        HapticFeedback.lightImpact();
                        context.read<ExpenseState>().renameMe(n);
                      },
                    ),
                    child: _AvatarBadge(
                      label: state.myName.substring(0, 1).toUpperCase(),
                      bg: Colors.white,
                      textColor: C.mango,
                      showEditDot: true,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-10, 0),
                  child: Tooltip(
                    message: 'Tap to rename',
                    child: GestureDetector(
                      onTap: () => _showRenameDialog(
                        context,
                        currentName: state.roommateName,
                        label: 'Roommate\'s name',
                        onSave: (n) {
                          HapticFeedback.lightImpact();
                          context.read<ExpenseState>().renameRoommate(n);
                        },
                      ),
                      child: _AvatarBadge(
                        label: state.roommateName.substring(0, 1).toUpperCase(),
                        bg: Colors.white.withValues(alpha: 0.6),
                        textColor: Colors.white,
                        showEditDot: true,
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              _HStat('Total Spent', 'Rs. ${state.total.toStringAsFixed(0)}'),
              _vDiv(),
              _HStat('Your Share', 'Rs. ${state.myShare.toStringAsFixed(0)}'),
              _vDiv(),
              _HStat('Count', '${state.expenses.length} bills'),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _vDiv() => Container(
    width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.white24,
  );

  void _showRenameDialog(
    BuildContext context, {
      required String currentName,
      required String label,
      required void Function(String) onSave,
    }) {
    HapticFeedback.lightImpact();
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(label, style: GoogleFonts.nunito(
          fontSize: 18, fontWeight: FontWeight.w900, color: C.ink)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.nunito(fontSize: 15, color: C.ink, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Enter a name…',
              hintStyle: GoogleFonts.nunito(color: C.muted),
              filled: true, fillColor: C.cardWhite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: C.mango, width: 1.5)),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: C.muted.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () { ctrl.dispose(); Navigator.pop(ctx); },
              child: Text('Cancel', style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700, color: C.subtext)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: C.mango, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                onSave(ctrl.text);
                ctrl.dispose();
                Navigator.pop(ctx);
              },
              child: Text('Save', style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
      ),
    );
    }
}

class _AvatarBadge extends StatelessWidget {
  final String label;
  final Color bg, textColor;
  final bool showEditDot;
  const _AvatarBadge({
    required this.label, required this.bg, required this.textColor,
    this.showEditDot = false,
  });

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg,
                                  border: Border.all(color: Colors.white60, width: 2)),
                                  child: Center(child: Text(label, style: GoogleFonts.nunito(
                                    fontSize: 14, fontWeight: FontWeight.w900, color: textColor))),
      ),
      if (showEditDot)
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: C.mango.withValues(alpha: 0.6), width: 1),
            ),
            child: const Icon(Icons.edit, size: 7, color: C.mango),
          ),
        ),
    ],
  );
}

class _HStat extends StatelessWidget {
  final String label, value;
  const _HStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.nunito(
        fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.nunito(
          fontSize: 14, color: Colors.white, fontWeight: FontWeight.w800)),
    ],
  );
}

class _BalanceCard extends StatelessWidget {
  final ExpenseState state;
  const _BalanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final pos      = state.theyOweMe;
    final accent   = pos ? C.sage : C.rose;
    final bgCircle = pos ? const Color(0xFFEDF7F2) : const Color(0xFFFFF0F4);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.cardWhite, borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(state.balanceLabel, style: GoogleFonts.nunito(
            fontSize: 13, color: C.subtext, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _AnimAmt(
                amount: state.balanceAmount,
                style: GoogleFonts.nunito(
                  fontSize: 44, fontWeight: FontWeight.w900,
                  color: accent, height: 1.1, letterSpacing: -1),
              ),
            ),
            const SizedBox(height: 14),
            if (!state.isSettled)
              GestureDetector(
                onTap: () => _showSettleSheet(context, state),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline_rounded, size: 15, color: accent),
                      const SizedBox(width: 6),
                      Text('Settle Up', style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
                    ]),
                ),
              )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: C.sage.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.celebration_rounded, size: 15, color: C.sage),
                      const SizedBox(width: 6),
                      Text('All settled! 🎉', style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w700, color: C.sage)),
                    ]),
                ),
        ])),
        const SizedBox(width: 16),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bgCircle),
          child: Icon(pos ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: accent, size: 32),
        ),
      ]),
    );
  }

  void _showSettleSheet(BuildContext context, ExpenseState state) {
    HapticFeedback.lightImpact();
    final debtor   = state.theyOweMe ? state.roommateName : 'you';
    final creditor = state.theyOweMe ? 'you' : state.roommateName;
    final amount   = state.balanceAmount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: C.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(
              width: 38, height: 4,
              decoration: BoxDecoration(
                color: C.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    color: C.sage.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.handshake_outlined, color: C.sage, size: 32),
                ),
                const SizedBox(height: 20),
                Text('Record Settlement?', style: GoogleFonts.nunito(
                  fontSize: 20, fontWeight: FontWeight.w900, color: C.ink)),
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.nunito(fontSize: 14, color: C.subtext,
                                                fontWeight: FontWeight.w600, height: 1.5),
                                   children: [
                                     const TextSpan(text: 'Record a payment of '),
                                     TextSpan(
                                       text: 'Rs. ${amount.toStringAsFixed(0)}',
                                       style: GoogleFonts.nunito(
                                         fontSize: 14, color: C.ink, fontWeight: FontWeight.w900),
                                     ),
                                   TextSpan(text: ' paid by $debtor to $creditor?\nThis will bring the balance to '),
                                   TextSpan(
                                     text: 'Rs. 0',
                                     style: GoogleFonts.nunito(
                                       fontSize: 14, color: C.sage, fontWeight: FontWeight.w900),
                                   ),
                                   const TextSpan(text: '.'),
                                   ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: C.muted.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: GoogleFonts.nunito(
                              fontSize: 14, fontWeight: FontWeight.w700, color: C.subtext)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.sage, foregroundColor: Colors.white,
                          elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.read<ExpenseState>().settleUp();
                              Navigator.pop(context);
                            },
                            child: Text('Confirm & Settle', style: GoogleFonts.nunito(
                              fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ]),
          ]),
      ),
    );
  }
}

class _SplitCard extends StatelessWidget {
  final ExpenseState state;
  const _SplitCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final ratio = state.total == 0 ? 0.5
    : (state.paidByMe / state.total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: C.cardWhite, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Payment Split', style: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w800, color: C.ink)),
            Text('${(ratio * 100).toStringAsFixed(0)}% · ${((1 - ratio) * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.nunito(
              fontSize: 12, fontWeight: FontWeight.w600, color: C.subtext)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Stack(children: [
              Container(height: 8, color: C.rose.withValues(alpha: 0.18)),
              FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [C.mango, C.sage]),
                    borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _SplitLbl(state.myName,       state.paidByMe,   C.mango),
          _SplitLbl(state.roommateName, state.paidByThem, C.rose, right: true),
        ]),
      ]),
    );
  }
}

class _SplitLbl extends StatelessWidget {
  final String name; final double amount; final Color color; final bool right;
  const _SplitLbl(this.name, this.amount, this.color, {this.right = false});

  @override
  Widget build(BuildContext context) {
    final dot = Container(width: 7, height: 7,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: color));
    final text = Column(
      crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(name, style: GoogleFonts.nunito(
          fontSize: 11, color: C.subtext, fontWeight: FontWeight.w600)),
          Text('Rs. ${amount.toStringAsFixed(0)}',
          style: GoogleFonts.nunito(
            fontSize: 13, fontWeight: FontWeight.w800, color: C.ink)),
      ],
    );
    return right
    ? Row(children: [text, const SizedBox(width: 6), dot])
    : Row(children: [dot, const SizedBox(width: 6), text]);
  }
}

class _Pill extends StatelessWidget {
  final String label; final Color color;
  const _Pill(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.nunito(
        fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  );
}

class _Tile extends StatefulWidget {
  final Expense expense;
  final void Function(Expense) onDismissed;
  const _Tile({required this.expense, required this.onDismissed});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(duration: const Duration(milliseconds: 320), vsync: this)
  ..forward();
  late final Animation<double> _fade =
  CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08), end: Offset.zero)
  .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final e     = widget.expense;
    final s     = context.watch<ExpenseState>();
    final iPaid = e.paidBy == 'Me';
    final diff  = DateTime.now().difference(e.date).inDays;
    final when  = diff == 0 ? 'Today' : diff == 1 ? 'Yesterday' : '${diff}d ago';
    final payerLabel = iPaid ? '🙋 ${s.myName}' : '🧑 ${s.roommateName}';

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
              color: C.rose.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.delete_outline_rounded, color: C.rose, size: 22),
                const SizedBox(height: 4),
                Text('Delete', style: GoogleFonts.nunito(
                  fontSize: 10, fontWeight: FontWeight.w700, color: C.rose)),
              ]),
          ),
          child: GestureDetector(
            onTap: e.isSettlement ? null : () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _ExpenseSheet(existing: e),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: e.isSettlement
                ? C.sage.withValues(alpha: 0.05)
                : C.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: e.isSettlement
                ? Border.all(color: C.sage.withValues(alpha: 0.25), width: 1)
                : null,
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: e.isSettlement
                    ? C.sage.withValues(alpha: 0.1)
                    : e.cat.bg,
                    borderRadius: BorderRadius.circular(14)),
                    child: Icon(
                      e.isSettlement ? Icons.handshake_outlined : e.cat.icon,
                      color: e.isSettlement ? C.sage : e.cat.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(e.title,
                                           style: GoogleFonts.nunito(
                                             fontSize: 14, fontWeight: FontWeight.w700, color: C.ink),
                                             maxLines: 1, overflow: TextOverflow.ellipsis)),
                                             if (e.isSettlement)
                                               Container(
                                                 margin: const EdgeInsets.only(left: 6),
                                                 padding: const EdgeInsets.symmetric(
                                                   horizontal: 6, vertical: 2),
                                                   decoration: BoxDecoration(
                                                     color: C.sage.withValues(alpha: 0.12),
                                                     borderRadius: BorderRadius.circular(6)),
                                                     child: Text('SETTLED', style: GoogleFonts.nunito(
                                                       fontSize: 8, fontWeight: FontWeight.w800,
                                                       color: C.sage, letterSpacing: 0.5)),
                                               )
                                               else
                                                 Icon(Icons.edit_outlined,
                                                      size: 13, color: C.muted.withValues(alpha: 0.6)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: iPaid
                            ? C.mango.withValues(alpha: 0.1)
                            : C.softGray,
                            borderRadius: BorderRadius.circular(20)),
                            child: Text(payerLabel,
                                        style: GoogleFonts.nunito(
                                          fontSize: 10, fontWeight: FontWeight.w700,
                                          color: iPaid ? C.mango : C.subtext)),
                      ),
                      const SizedBox(width: 8),
                      Text(when, style: GoogleFonts.nunito(
                        fontSize: 11, color: C.muted, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                )),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Rs. ${e.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w900, color: C.ink)),
                    const SizedBox(height: 2),
                    Text('Rs. ${(e.amount / 2).toStringAsFixed(0)}/ea',
                    style: GoogleFonts.nunito(
                      fontSize: 10, color: C.muted, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimAmt extends StatefulWidget {
  final double amount; final TextStyle style;
  const _AnimAmt({required this.amount, required this.style});
  @override
  State<_AnimAmt> createState() => _AnimAmtState();
}

class _AnimAmtState extends State<_AnimAmt> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 550), vsync: this);
    _a = Tween<double>(begin: 0, end: widget.amount)
    .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void didUpdateWidget(_AnimAmt old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount) {
      _prev = old.amount;
      _a = Tween<double>(begin: _prev, end: widget.amount)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
      _c.forward(from: 0);
    }
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, _) =>
    Text('Rs. ${_a.value.toStringAsFixed(0)}', style: widget.style),
  );
}

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
        boxShadow: [BoxShadow(
          color: C.mango.withValues(alpha: 0.38),
          blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 7),
        Text('Add Expense', style: GoogleFonts.nunito(
          fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    ),
  );
}

class _ExpenseSheet extends StatefulWidget {
  final Expense? existing;
  const _ExpenseSheet({this.existing});

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late String _payer;
  late Cat    _cat;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl  = TextEditingController(text: e?.title  ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(0) : '');
    _payer = e?.paidBy ?? 'Me';
    _cat   = e?.cat    ?? cats[0];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final s = context.read<ExpenseState>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90),
        decoration: const BoxDecoration(
          color: C.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Center(child: Container(
                width: 38, height: 4,
                decoration: BoxDecoration(
                  color: C.muted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10)))),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22, 10, 22, bottom + 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_isEditing ? 'Edit Expense' : 'Add Expense',
                           style: GoogleFonts.nunito(
                             fontSize: 22, fontWeight: FontWeight.w900, color: C.ink)),
                      if (_isEditing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: C.mango.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20)),
                              child: Text('Editing', style: GoogleFonts.nunito(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: C.mango)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text('Category', style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w700, color: C.subtext)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = cats[i]; final sel = c == _cat;
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
                                  ? c.color.withValues(alpha: 0.45)
                                  : Colors.transparent,
                                  width: 1.5)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(c.icon,
                                           color: sel ? c.color : C.muted, size: 20),
                                           const SizedBox(height: 4),
                                           Text(
                                             c.short.length > 6
                                             ? '${c.short.substring(0, 5)}.'
                                           : c.short,
                                           style: GoogleFonts.nunito(
                                             fontSize: 9, fontWeight: FontWeight.w700,
                                             color: sel ? c.color : C.muted),
                                             textAlign: TextAlign.center,
                                           ),
                                    ]),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    _Field(ctrl: _titleCtrl, label: 'Description',
                           hint: 'e.g. Electricity Bill'),
                           const SizedBox(height: 12),
                           _Field(ctrl: _amountCtrl, label: 'Amount', hint: '0',
                                  prefix: 'Rs. ',
                                  kb: const TextInputType.numberWithOptions(decimal: true)),
                                  const SizedBox(height: 20),

                                  Text('Who paid?', style: GoogleFonts.nunito(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: C.subtext)),
                              const SizedBox(height: 10),
                              Row(children: [
                                _PayBtn(
                                  '🙋  ${s.myName}',
                                  _payer == 'Me', C.mango,
                                  () => setState(() => _payer = 'Me'),
                                ),
                                const SizedBox(width: 10),
                                _PayBtn(
                                  '🧑  ${s.roommateName}',
                                  _payer == 'Roommate', C.rose,
                                  () => setState(() => _payer = 'Roommate'),
                                ),
                              ]),
                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity, height: 54,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: C.mango, foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16))),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _save(context);
                                      },
                                      child: Text(
                                        _isEditing ? 'Save Changes' : 'Save Expense',
                                        style: GoogleFonts.nunito(
                                          fontSize: 15, fontWeight: FontWeight.w800,
                                          color: Colors.white),
                                      ),
                                ),
                              ),
                ]),
              ),
            ),
          ]),
    );
  }

  void _save(BuildContext context) {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) return;

    final state = context.read<ExpenseState>();
    if (_isEditing) {
      state.update(widget.existing!.id, _titleCtrl.text, amt, _payer, _cat);
    } else {
      state.add(_titleCtrl.text, amt, _payer, _cat);
    }
    Navigator.pop(context);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final String? prefix;
  final TextInputType? kb;
  const _Field({required this.ctrl, required this.label, required this.hint,
    this.prefix, this.kb});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, keyboardType: kb,
    style: GoogleFonts.nunito(
      fontSize: 15, color: C.ink, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label, hintText: hint, prefixText: prefix,
        labelStyle: GoogleFonts.nunito(
          fontSize: 13, color: C.subtext, fontWeight: FontWeight.w600),
          hintStyle: GoogleFonts.nunito(color: C.muted),
          prefixStyle: GoogleFonts.nunito(
            fontSize: 15, color: C.subtext, fontWeight: FontWeight.w700),
            filled: true, fillColor: C.cardWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: C.mango, width: 1.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
  );
}

class _PayBtn extends StatelessWidget {
  final String label; final bool sel; final Color color; final VoidCallback onTap;
  const _PayBtn(this.label, this.sel, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 46,
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.1) : C.softGray,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: sel ? color.withValues(alpha: 0.4) : Colors.transparent,
            width: 1.5)),
            child: Center(child: Text(label,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: sel ? color : C.subtext))),
      ),
    ),
  );
}
