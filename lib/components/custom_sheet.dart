import 'package:flutter/material.dart';

enum SheetSide { top, right, bottom, left }

class CustomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    SheetSide side = SheetSide.right,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Close",
      barrierColor: Colors.black54, // The "bg-black/50" scrim
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: _getAlignment(side),
          child: Material(
            color: const Color(0xFF020817), // bg-background
            child: SizedBox(
              width: side == SheetSide.left || side == SheetSide.right ? 320 : double.infinity,
              height: side == SheetSide.top || side == SheetSide.bottom ? 300 : double.infinity,
              child: Stack(
                children: [
                  child,
                  // The "X" Close Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: _getBeginOffset(side),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  static Alignment _getAlignment(SheetSide side) {
    switch (side) {
      case SheetSide.top: return Alignment.topCenter;
      case SheetSide.bottom: return Alignment.bottomCenter;
      case SheetSide.left: return Alignment.centerLeft;
      case SheetSide.right: return Alignment.centerRight;
    }
  }

  static Offset _getBeginOffset(SheetSide side) {
    switch (side) {
      case SheetSide.top: return const Offset(0, -1);
      case SheetSide.bottom: return const Offset(0, 1);
      case SheetSide.left: return const Offset(-1, 0);
      case SheetSide.right: return const Offset(1, 0);
    }
  }
}