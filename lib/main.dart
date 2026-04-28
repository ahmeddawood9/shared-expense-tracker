import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'expense_state.dart';
import 'dashboard_screen.dart';
import 'constants.dart';

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
        primary: C.mango,
        secondary: C.sage,
        surface: C.cardWhite,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme),
      useMaterial3: true,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: C.ink,
        actionTextColor: C.mango,
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    ),
    home: const DashboardScreen(),
  );
}
