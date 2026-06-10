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
  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1F35);
  static const Color lightTextSecondary = Color(0xFF5C6B8A);

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.electricBlue,
        secondary: AppColors.electricBlue,
        error: AppColors.dangerRed,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        onBackground: lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: lightTextPrimary,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightTextPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightTextSecondary,
          height: 1.4,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.electricBlue),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: AppColors.electricBlue.withValues(alpha: 0.15),
      ),
    );
  }

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

/// Theme-aware colors for screens that previously used static [AppColors].
class AdaptiveTheme {
  final bool isDark;
  const AdaptiveTheme(this.isDark);

  Color get background => isDark ? AppColors.background : AppTheme.lightBackground;
  Color get surface => isDark ? AppColors.secondaryBg : AppTheme.lightSurface;
  Color get surfaceAlt => isDark ? AppColors.tertiaryBg : const Color(0xFFE8ECF4);
  Color get textPrimary => isDark ? AppColors.textPrimary : AppTheme.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondary : AppTheme.lightTextSecondary;
  Color get glassBg => isDark ? AppColors.glassBg : const Color(0xCCFFFFFF);
  Color get glassBorder => isDark ? AppColors.glassBorder : const Color(0x22000000);
  Color get cardSurface => isDark ? const Color(0xFF0C1224) : AppTheme.lightSurface;
  Color get sectionDivider => isDark ? const Color(0xFF1A2238) : const Color(0xFFE2E8F0);
  Color get subtleBorder => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.08);
  Color get emptyFill => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.06);
}

extension AdaptiveThemeContext on BuildContext {
  AdaptiveTheme get adaptive =>
      AdaptiveTheme(Theme.of(this).brightness == Brightness.dark);
}
