import 'package:flutter/material.dart';

class UIUtils {
  // A clean way to handle your dark-themed border
  static const BorderSide defaultBorder = BorderSide(
    color: Color(0x1FFFFFFF), // Equivalent to border-input
    width: 1.0,
  );

  // A helper to merge complex Decorations if needed
  static BoxDecoration cardDecoration = BoxDecoration(
    color: const Color(0xFF0F172A), // bg-popover
    borderRadius: BorderRadius.circular(6),
    border: const Border.fromBorderSide(defaultBorder),
  );
}