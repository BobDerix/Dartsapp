import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0D0D0F);
  static const surface = Color(0xFF161619);
  static const card = Color(0xFF1E1E22);
  static const cardBorder = Color(0xFF2A2A30);

  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFF8A8A94);
  static const textMuted = Color(0xFF5A5A64);

  // Brand colors from logo
  static const cyan = Color(0xFF00BCD4);       // DART-CORE metallic cyan
  static const cyanLight = Color(0xFF4DD0E1);   // Lighter cyan for gradients
  static const cyanDark = Color(0xFF00838F);     // Darker cyan for depth
  static const gold = Color(0xFFFFB300);         // BONANZA warm gold
  static const goldLight = Color(0xFFFFCA28);    // Lighter gold for gradients
  static const goldDark = Color(0xFFE65100);     // Deep amber for depth

  // Player colors = brand colors
  static const player1 = cyan;
  static const player2 = gold;

  static const hit = Color(0xFF00E676);
  static const miss = Color(0xFFFF1744);
  static const neutral = Color(0xFF7C4DFF);

  // Category colors (shifted to match brand palette)
  static const catPrecision = Color(0xFF78909C);
  static const catScoring = Color(0xFF00BCD4);
  static const catFinish = Color(0xFFFFB300);
  static const catBattle = Color(0xFFFF5252);
  static const catSpecial = Color(0xFF7C4DFF);

  // Chaos card colors
  static const chaosGold = Color(0xFFFFD700);
  static const chaosBackground = Color(0xFF1A0033);
  static const chaosBorder = Color(0xFFFF6B00);

  // Commentary / timer
  static const commentaryBg = Color(0xFF121218);
  static const timerWarning = Color(0xFFFF4444);
  static const timerNormal = Color(0xFF00E676);

  static Color categoryColor(String category) => switch (category.toUpperCase()) {
    'PRECISION' => catPrecision,
    'SCORING' => catScoring,
    'FINISH' => catFinish,
    'BATTLE' => catBattle,
    'SPECIAL' => catSpecial,
    _ => neutral,
  };
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      secondary: AppColors.gold,
      surface: AppColors.surface,
      error: AppColors.miss,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF252528),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1,
      ),
    ),
    useMaterial3: true,
  );
}
