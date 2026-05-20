import 'package:flutter/material.dart';

class CustomLabel extends StatelessWidget {
  final String text;
  final bool isDisabled;
  final TextStyle? style;

  const CustomLabel({
    super.key,
    required this.text,
    this.isDisabled = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0, // peer-disabled:opacity-50
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.0, // text-sm
          fontWeight: FontWeight.w500, // font-medium
          height: 1.0, // leading-none
          color: Colors.white, // Default dark theme text
        ).merge(style), // Allows you to merge in custom colors/sizes if ever needed
      ),
    );
  }
}