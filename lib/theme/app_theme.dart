import 'package:flutter/material.dart';

class AppTheme {
  // Define your brand colors here
  static const Color background = Color(0xFF020817);
  static const Color surface = Color(0xFF0F172A);
  static const Color primary = Color(0xFF00D4FF);
  static const Color accent = Color(0xFF00FF88);
  static const Color error = Color(0xFFFF2D55);
  static const Color textSecondary = Color(0xFF8B92A8);

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      error: error,
      surface: surface,
    ),
  );
}