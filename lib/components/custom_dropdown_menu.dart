import 'package:flutter/material.dart';

enum DropdownMenuItemType { label, standard, checkbox, divider }

class CustomDropdownItem {
  final String? label;
  final IconData? icon;
  final DropdownMenuItemType type;
  final bool checked;
  final bool isDestructive;
  final VoidCallback? onTap;

  const CustomDropdownItem({
    this.label,
    this.icon,
    this.type = DropdownMenuItemType.standard,
    this.checked = false,
    this.isDestructive = false,
    this.onTap,
  });

  // Shortcut for headers (DropdownMenuLabel)
  factory CustomDropdownItem.label(String text) {
    return CustomDropdownItem(label: text, type: DropdownMenuItemType.label);
  }

  // Shortcut for dividers (DropdownMenuSeparator)
  factory CustomDropdownItem.separator() {
    return const CustomDropdownItem(type: DropdownMenuItemType.divider);
  }
}

class CustomDropdownMenu extends StatelessWidget {
  final Widget trigger; // The button or widget you tap to open the menu
  final List<CustomDropdownItem> items;

  const CustomDropdownMenu({
    super.key,
    required this.trigger,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CustomDropdownItem>(
      // 1. Structural appearance matching dark popover theme
      color: const Color(0xFF0F172A), // bg-popover
      elevation: 8,
      offset: const Offset(0, 48), // Drops down just below the trigger button
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0), // rounded-md
        side: const BorderSide(color: Colors.white12, width: 1.0), // border
      ),
      // 2. Wrap the child so the PopupMenu knows what to track for clicks
      child: trigger,
      // 3. Execution action router
      onSelected: (CustomDropdownItem selectedAction) {
        if (selectedAction.onTap != null && selectedAction.type != DropdownMenuItemType.label) {
          selectedAction.onTap!();
        }
      },
      // 4. Map the logical items into visual Flutter list tiles
      itemBuilder: (BuildContext context) {
        return items.map((item) {
          // Render Separator
          if (item.type == DropdownMenuItemType.divider) {
            return const PopupMenuDivider(height: 1) as PopupMenuEntry<CustomDropdownItem>;
          }

          // Render Label (non-clickable header)
          if (item.type == DropdownMenuItemType.label) {
            return PopupMenuItem<CustomDropdownItem>(
              value: item,
              enabled: false, // Prevents hover/tap
              height: 32,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0), // pl-8 alignment
                child: Text(
                  item.label ?? '',
                  style: const TextStyle(
                    fontSize: 14, // text-sm
                    fontWeight: FontWeight.w500, // font-medium
                    color: Colors.white, // text-foreground
                  ),
                ),
              ),
            );
          }

          // Render Standard or Checkbox item
          return PopupMenuItem<CustomDropdownItem>(
            value: item,
            height: 36,
            child: Row(
              children: [
                // Icon / Checkbox Slot
                SizedBox(
                  width: 28,
                  child: item.type == DropdownMenuItemType.checkbox
                      ? Icon(
                          item.checked ? Icons.check : null,
                          size: 16,
                          color: Colors.white,
                        )
                      : (item.icon != null
                          ? Icon(item.icon, size: 16, color: item.isDestructive ? Colors.red[400] : Colors.white70)
                          : null),
                ),
                // Text Label Slot
                Expanded(
                  child: Text(
                    item.label ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: item.isDestructive ? Colors.red[400] : Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}