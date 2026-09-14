import 'package:flutter/material.dart';
import '../models/fire_event.dart';

/// Central color + theme definitions for RiskMap.
/// Palette: deep forest green background, warm ember orange/red accents.
class AppColors {
  static const Color forestDark = Color(0xFF10241C);
  static const Color forestMid = Color(0xFF1B3A2C);
  static const Color forestCard = Color(0xFF213F30);
  static const Color emberOrange = Color(0xFFFF7A33);
  static const Color emberRed = Color(0xFFE84C3D);
  static const Color amber = Color(0xFFFFB347);
  static const Color mist = Color(0xFFB8C9BE);
  static const Color textPrimary = Color(0xFFF3F7F4);
  static const Color textMuted = Color(0xFF8FA79A);

  static const Color riskLow = Color(0xFF4CAF7D);
  static const Color riskModerate = Color(0xFFFFB347);
  static const Color riskHigh = Color(0xFFFF7A33);
  static const Color riskCritical = Color(0xFFE84C3D);

  static Color forRisk(FireRiskLevel level) {
    switch (level) {
      case FireRiskLevel.low:
        return riskLow;
      case FireRiskLevel.moderate:
        return riskModerate;
      case FireRiskLevel.high:
        return riskHigh;
      case FireRiskLevel.critical:
        return riskCritical;
    }
  }
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.forestDark,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.emberOrange,
        secondary: AppColors.amber,
        surface: AppColors.forestCard,
        error: AppColors.emberRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.forestDark,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.forestCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.forestMid,
        indicatorColor: AppColors.emberOrange.withOpacity(0.25),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.emberOrange : AppColors.textMuted,
          );
        }),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      useMaterial3: true,
    );
  }
}
