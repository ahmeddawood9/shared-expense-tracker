import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'models.dart';
import 'expense_state.dart';

// ════════════════════════════════════════════════════════════
//  EMPTY STATE
// ════════════════════════════════════════════════════════════
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: C.mango.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: C.mango,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No expenses yet!',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: C.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Tap "Add Expense" below to log your first shared bill.\nKeeping track is caring! 🏠',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: C.subtext,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: C.mango.withOpacity(0.5),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  DATE GROUP HEADER
// ════════════════════════════════════════════════════════════
class DateHeader extends StatelessWidget {
  final String label;
  const DateHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: C.subtext,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(color: C.muted.withOpacity(0.35), thickness: 1),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  PILL
// ════════════════════════════════════════════════════════════
class Pill extends StatelessWidget {
  final String label;
  final Color color;
  const Pill(this.label, this.color, {super.key});
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

// ════════════════════════════════════════════════════════════
//  ANIMATED AMOUNT
// ════════════════════════════════════════════════════════════
class AnimAmt extends StatefulWidget {
  final double amount;
  final TextStyle style;
  const AnimAmt({super.key, required this.amount, required this.style});
  @override
  State<AnimAmt> createState() => _AnimAmtState();
}

class _AnimAmtState extends State<AnimAmt>
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
  void didUpdateWidget(AnimAmt old) {
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

// ════════════════════════════════════════════════════════════
//  ADD BUTTON
// ════════════════════════════════════════════════════════════
class AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const AddBtn({super.key, required this.onTap});

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

// ════════════════════════════════════════════════════════════
//  TEXT FIELD
// ════════════════════════════════════════════════════════════
class CustomField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final String? prefix;
  final TextInputType? kb;
  const CustomField({
    super.key,
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
