import 'package:flutter/material.dart';

enum ContextMenuItemType { standard, checkbox, divider }

class CustomContextMenuItem {
  final String? label;
  final IconData? icon;
  final ContextMenuItemType type;
  final bool checked;
  final bool isDestructive;
  final VoidCallback? onTap;

  const CustomContextMenuItem({
    this.label,
    this.icon,
    this.type = ContextMenuItemType.standard,
    this.checked = false,
    this.isDestructive = false,
    this.onTap,
  });

  // Shortcut for quick horizontal separators
  factory CustomContextMenuItem.separator() {
    return const CustomContextMenuItem(type: ContextMenuItemType.divider);
  }
}

class CustomContextMenuWrapper extends StatelessWidget {
  final Widget child;
  final List<CustomContextMenuItem> items;

  const CustomContextMenuWrapper({
    super.key,
    required this.child,
    required this.items,
  });

  void _showContextMenu(BuildContext context, Offset globalPosition) async {
    // Capture the exact touch/click coordinates on the screen
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    // Render the native popup menu panel mapped to our dark theme
    final selectedAction = await showMenu<CustomContextMenuItem>(
      context: context,
      position: position,
      color: const Color(0xFF0F172A), // bg-popover / Slate Dark
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0), // rounded-md
        side: const BorderSide(color: Colors.white12, width: 1.0),
      ),
      items: items.map((item) {
        if (item.type == ContextMenuItemType.divider) {
          return const PopupMenuDivider(height: 1) as PopupMenuEntry<CustomContextMenuItem>;
        }

        return PopupMenuItem<CustomContextMenuItem>(
          value: item,
          height: 36,
          child: Row(
            children: [
              // Checkbox / Icon Slot
              SizedBox(
                width: 24,
                child: item.type == ContextMenuItemType.checkbox
                    ? Icon(
                        item.checked ? Icons.check : null,
                        size: 16,
                        color: Colors.white,
                      )
                    : (item.icon != null
                        ? Icon(item.icon, size: 16, color: item.isDestructive ? Colors.red[400] : Colors.white70)
                        : null),
              ),
              const SizedBox(width: 8),
              // Item Text
              Text(
                item.label ?? '',
                style: TextStyle(
                  fontSize: 14, // text-sm
                  color: item.isDestructive ? Colors.red[400] : Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    // Execute the bound callback if an item was chosen
    if (selectedAction != null && selectedAction.onTap != null) {
      selectedAction.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Both pass their respective global screen positions down to our handler safely now
      onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
      onLongPressDown: (details) => _showContextMenu(context, details.globalPosition),
      child: child,
    );
  }
}