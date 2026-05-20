import 'package:flutter/material.dart';

/// A helper function to show a standardized EVision alert dialog.
Future<void> showCustomAlertDialog({
  required BuildContext context,
  required String title,
  required String description,
  String cancelText = 'Cancel',
  String actionText = 'Continue',
  VoidCallback? onCancel,
  required VoidCallback onAction,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54, // Matches the bg-black/50 overlay
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0F172A), // Dark slate background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // rounded-lg
          side: const BorderSide(color: Colors.white12), // border
        ),
        titlePadding: const EdgeInsets.all(24), // p-6 equivalent
        contentPadding: EdgeInsets.zero,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // AlertDialogTitle
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // AlertDialogDescription
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        actions: [
          // AlertDialogFooter
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // AlertDialogCancel
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Closes the dialog
                  if (onCancel != null) onCancel();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(cancelText),
              ),
              const SizedBox(width: 8),
              // AlertDialogAction
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Closes the dialog
                  onAction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(actionText),
              ),
            ],
          ),
        ],
      );
    },
  );
}