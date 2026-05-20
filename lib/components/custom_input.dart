import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool hasError; 
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const CustomInput({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Determine border colors based on active error states
    final Color defaultBorderColor = hasError ? Colors.red[400]! : Colors.white12;
    final Color focusBorderColor = hasError ? Colors.red[400]! : Colors.white70;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        color: enabled ? Colors.white : Colors.white54,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF0F172A), // bg-input/30 dark slate background
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        
        // 1. Default resting border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: defaultBorderColor, width: 1.0),
        ),
        // 2. Enabled border (when not focused)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: defaultBorderColor, width: 1.0),
        ),
        // 3. Focused border (Simulates the focus-visible:ring behavior)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: focusBorderColor, width: 2.0),
        ),
        // 4. Disabled border
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: const BorderSide(color: Colors.white12, width: 1.0),
        ),
      ),
    );
  }
}