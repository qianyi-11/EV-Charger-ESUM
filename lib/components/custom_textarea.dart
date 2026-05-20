import 'package:flutter/material.dart';

class CustomTextarea extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final int minLines;
  final int? maxLines;

  const CustomTextarea({
    super.key,
    required this.controller,
    this.placeholder = "Enter text...",
    this.minLines = 3,
    this.maxLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Colors.white38), // muted-foreground
        filled: true,
        fillColor: const Color(0xFF020817), // bg-input-background
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.white12), // border-input
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2), // ring-ring
        ),
      ),
    );
  }
}