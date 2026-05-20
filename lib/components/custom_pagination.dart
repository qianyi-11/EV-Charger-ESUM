import 'dart:math';
import 'package:flutter/material.dart';

class CustomPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const CustomPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous Button
        _buildNavButton(
          label: "Previous",
          icon: Icons.chevron_left,
          isNext: false,
          isEnabled: currentPage > 1,
        ),
        
        const SizedBox(width: 8),

        // Dynamic Page Numbers & Ellipses
        ..._buildPageItems(),

        const SizedBox(width: 8),

        // Next Button
        _buildNavButton(
          label: "Next",
          icon: Icons.chevron_right,
          isNext: true,
          isEnabled: currentPage < totalPages,
        ),
      ],
    );
  }

  List<Widget> _buildPageItems() {
    List<Widget> items = [];

    // If we only have a few pages, just show all of them
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        items.add(_buildPageButton(i));
      }
    } else {
      // Always show the first page
      items.add(_buildPageButton(1));

      // Show left ellipsis if we are far enough from the start
      if (currentPage > 3) {
        items.add(_buildEllipsis());
      }

      // Show the pages immediately surrounding the current page
      final int startPage = max(2, currentPage - 1);
      final int endPage = min(totalPages - 1, currentPage + 1);
      
      for (int i = startPage; i <= endPage; i++) {
        items.add(_buildPageButton(i));
      }

      // Show right ellipsis if we are far enough from the end
      if (currentPage < totalPages - 2) {
        items.add(_buildEllipsis());
      }

      // Always show the last page
      items.add(_buildPageButton(totalPages));
    }

    return items;
  }

  Widget _buildPageButton(int page) {
    final bool isActive = page == currentPage;

    return Container(
      width: 36, // size-9 equivalent
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      child: TextButton(
        onPressed: () => onPageChanged(page),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isActive ? Colors.white12 : Colors.transparent, // Active: outline/bg-accent, Inactive: ghost
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0), // rounded-md
            side: isActive 
                ? const BorderSide(color: Colors.white24, width: 1) // Outline variant
                : BorderSide.none, // Ghost variant
          ),
        ),
        child: Text(
          page.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: const Icon(Icons.more_horiz, size: 16, color: Colors.white54),
    );
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required bool isNext,
    required bool isEnabled,
  }) {
    return TextButton(
      onPressed: isEnabled ? () => onPageChanged(isNext ? currentPage + 1 : currentPage - 1) : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38, // disabled:opacity-50
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNext) Icon(icon, size: 18),
          if (!isNext) const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 14)),
          if (isNext) const SizedBox(width: 4),
          if (isNext) Icon(icon, size: 18),
        ],
      ),
    );
  }
}