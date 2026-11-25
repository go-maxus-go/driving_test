import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class SemanticColors {
  const SemanticColors({
    required this.correctBorder,
    required this.correctSurface,
    required this.correctText,
    required this.wrongBorder,
    required this.wrongSurface,
    required this.wrongText,
    required this.missedBorder,
    required this.missedSurface,
    required this.missedText,
    required this.cardSurface,
    required this.subtleBorder,
  });

  final Color correctBorder;
  final Color correctSurface;
  final Color correctText;
  final Color wrongBorder;
  final Color wrongSurface;
  final Color wrongText;
  final Color missedBorder;
  final Color missedSurface;
  final Color missedText;
  final Color cardSurface;
  final Color subtleBorder;

  static SemanticColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const SemanticColors(
        correctBorder: Color(0xFF22C55E),
        correctSurface: Color(0xFF052E16),
        correctText: Color(0xFF86EFAC),
        wrongBorder: Color(0xFFEF4444),
        wrongSurface: Color(0xFF450A0A),
        wrongText: Color(0xFFFCA5A5),
        missedBorder: Color(0xFFF59E0B),
        missedSurface: Color(0xFF451A03),
        missedText: Color(0xFFFDE68A),
        cardSurface: Color(0xFF162032),
        subtleBorder: Color(0xFF293548),
      );
    }
    return const SemanticColors(
      correctBorder: Color(0xFF15803D),
      correctSurface: Color(0xFFDCFCE7),
      correctText: Color(0xFF14532D),
      wrongBorder: Color(0xFFB91C1C),
      wrongSurface: Color(0xFFFEE2E2),
      wrongText: Color(0xFF7F1D1D),
      missedBorder: Color(0xFFD97706),
      missedSurface: Color(0xFFFEF3C7),
      missedText: Color(0xFF78350F),
      cardSurface: Color(0xFFFFFFFF),
      subtleBorder: Color(0xFFE2E8F0),
    );
  }
}

class AppTheme {
  const AppTheme._();

  static const Color autobahnBlue = Color(0xFF1D4ED8);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: autobahnBlue,
      brightness: Brightness.light,
      primary: autobahnBlue,
      surface: const Color(0xFFF8FAFC),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: autobahnBlue,
      brightness: Brightness.dark,
      primary: const Color(0xFF60A5FA),
      surface: const Color(0xFF0B1120),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF162032),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF293548)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
