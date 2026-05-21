import 'package:flutter/material.dart';

class AppColors {
  static const Color electricBlue = Color(0xFF00D4FF);
  static const Color dangerRed = Color(0xFFFF2D55);
  static const Color successGreen = Color(0xFF00FF88);
  static const Color warningOrange = Color(0xFFFFA500);
  
  static const Color background = Color(0xFF0A0E1A);
  static const Color secondaryBg = Color(0xFF1A1F35);
  static const Color tertiaryBg = Color(0xFF1E2436);
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8F9BB3);
  static const Color glassBorder = Color(0x1BFFFFFF);
  static const Color glassBg = Color(0x1A0F1423);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricBlue,
        secondary: AppColors.electricBlue,
        error: AppColors.dangerRed,
        surface: AppColors.secondaryBg,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.electricBlue,
      ),
    );
  }

  static BoxDecoration glassDecoration({
    BorderRadius? borderRadius,
    Color? borderGradientStart,
    Color? borderGradientEnd,
  }) {
    return BoxDecoration(
      color: AppColors.glassBg,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: AppColors.glassBorder),
    );
  }

  static List<BoxShadow> glowShadow({Color color = AppColors.electricBlue, double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.25 * intensity),
        blurRadius: 16 * intensity,
        spreadRadius: 1 * intensity,
      ),
      BoxShadow(
        color: color.withOpacity(0.12 * intensity),
        blurRadius: 32 * intensity,
        spreadRadius: 2 * intensity,
      ),
    ];
  }
}
