import 'package:flutter/material.dart';

class AppColors {
  // Brand & Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF252525);
  
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF252525);
  
  static const Color primary = Color(0xFF030213);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  
  static const Color secondary = Color(0xFFF2F0FF);
  static const Color secondaryForeground = Color(0xFF030213);
  
  // Muted colors (used in main.dart)
  static const Color muted = Color(0xFFECECF0);
  static const Color mutedForeground = Color(0xFF717182);
  
  static const Color accent = Color(0xFFE9EBEF);
  static const Color accentForeground = Color(0xFF030213);
  
  // Destructive/Danger colors (mapped for compatibility)
  static const Color destructive = Color(0xFFD4183D);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFD4183D); // Added for main.dart compatibility
  
  static const Color border = Color(0x1A000000);
  static const Color input = Colors.transparent;
  static const Color inputBackground = Color(0xFFF3F3F5);
  
  static const Color ring = Color(0xFFB4B4B4);

  // Glassmorphism constants (used in glass_card.dart)
  static final Color glassBg = const Color(0xFF0F1423).withOpacity(0.6);
  static const Color glassBorder = Color(0x1AFFFFFF);
}