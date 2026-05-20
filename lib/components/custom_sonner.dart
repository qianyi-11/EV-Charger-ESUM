import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class CustomToaster {
  static void show({
    required BuildContext context,
    required String title,
    String? description,
    // Use 'ToastificationType' from the package
    ToastificationType type = ToastificationType.info,
  }) {
    toastification.show(
      context: context,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      description: description != null 
          ? Text(description, style: const TextStyle(color: Colors.white70)) 
          : null,
      type: type,
      // The modern API uses 'ToastificationStyle.flat' or similar
      style: ToastificationStyle.flat, 
      backgroundColor: const Color(0xFF0F172A),
      foregroundColor: Colors.white,
      applyBlurEffect: true,
      borderRadius: BorderRadius.circular(6.0),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }
}