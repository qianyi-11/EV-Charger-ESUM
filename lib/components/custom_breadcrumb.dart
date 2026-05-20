import 'package:flutter/material.dart';

/// A simple model to hold the data for each breadcrumb step
class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  final bool isCurrentPage;
  final bool isEllipsis;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
    this.isCurrentPage = false,
    this.isEllipsis = false,
  });

  /// A quick shortcut to create a "..." ellipsis item
  factory BreadcrumbItem.ellipsis({VoidCallback? onTap}) {
    return BreadcrumbItem(label: '...', isEllipsis: true, onTap: onTap);
  }
}

class CustomBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const CustomBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    List<Widget> breadcrumbWidgets = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      // 1. Add the actual item (Link, Page, or Ellipsis)
      if (item.isEllipsis) {
        breadcrumbWidgets.add(_buildEllipsis(item));
      } else if (item.isCurrentPage) {
        breadcrumbWidgets.add(_buildCurrentPage(item));
      } else {
        breadcrumbWidgets.add(_buildLink(item));
      }

      // 2. Add the Chevron separator (if it's not the last item)
      if (i < items.length - 1) {
        breadcrumbWidgets.add(_buildSeparator());
      }
    }

    // Wrap handles layout gracefully if the trail exceeds screen width
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6.0, // Tailwind gap-1.5
      runSpacing: 4.0, 
      children: breadcrumbWidgets,
    );
  }

  Widget _buildLink(BreadcrumbItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
        child: Text(
          item.label,
          style: TextStyle(
            fontSize: 14, // text-sm
            color: Colors.grey[400], // text-muted-foreground
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage(BreadcrumbItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
      child: Text(
        item.label,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white, // text-foreground
          fontWeight: FontWeight.w500, // font-medium for the active page
        ),
      ),
    );
  }

  Widget _buildEllipsis(BreadcrumbItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Icon(
          Icons.more_horiz,
          size: 16, // size-4
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Icon(
      Icons.chevron_right,
      size: 16, // size-3.5
      color: Colors.grey[500],
    );
  }
}