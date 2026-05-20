import 'package:flutter/material.dart';

enum MenubarItemType { standard, checkbox, divider, submenu }

class CustomMenubarItem {
  final String? label;
  final IconData? icon;
  final MenubarItemType type;
  final bool checked;
  final bool isDestructive;
  final String? shortcut;
  final VoidCallback? onTap;
  final List<CustomMenubarItem>? submenuItems;

  const CustomMenubarItem({
    this.label,
    this.icon,
    this.type = MenubarItemType.standard,
    this.checked = false,
    this.isDestructive = false,
    this.shortcut,
    this.onTap,
    this.submenuItems,
  });

  factory CustomMenubarItem.separator() {
    return const CustomMenubarItem(type: MenubarItemType.divider);
  }
}

class CustomMenubar extends StatelessWidget {
  /// Top level items act as the main buttons on the bar (e.g., "File", "View")
  final List<CustomMenubarItem> menus;

  const CustomMenubar({super.key, required this.menus});

  @override
  Widget build(BuildContext context) {
    // Shadcn popover styling applied globally to all dropdowns in this bar
    final MenuStyle popupStyle = MenuStyle(
      backgroundColor: WidgetStateProperty.all(const Color(0xFF0F172A)), // bg-popover
      elevation: WidgetStateProperty.all(8),
      padding: WidgetStateProperty.all(const EdgeInsets.all(4.0)), // p-1
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0), // rounded-md
          side: const BorderSide(color: Colors.white12, width: 1), // border
        ),
      ),
    );

    return Container(
      height: 36, // h-9
      decoration: BoxDecoration(
        color: const Color(0xFF020817), // bg-background
        borderRadius: BorderRadius.circular(6.0), // rounded-md
        border: Border.all(color: Colors.white12), // border
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: MenuBar(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(0),
        ),
        children: menus.map((menu) => _buildTopLevelMenu(menu, popupStyle)).toList(),
      ),
    );
  }

  Widget _buildTopLevelMenu(CustomMenubarItem menu, MenuStyle popupStyle) {
    return SubmenuButton(
      menuStyle: popupStyle,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return Colors.white; // focus:text-accent-foreground
          }
          return Colors.white70;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return Colors.white12; // focus:bg-accent
          }
          return Colors.transparent;
        }),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0))),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12.0)),
      ),
      menuChildren: _buildMenuItems(menu.submenuItems ?? [], popupStyle),
      child: Text(
        menu.label ?? '',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  List<Widget> _buildMenuItems(List<CustomMenubarItem> items, MenuStyle popupStyle) {
    return items.map((item) {
      if (item.type == MenubarItemType.divider) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Divider(height: 1, color: Colors.white12),
        );
      }

      if (item.type == MenubarItemType.submenu) {
        return SubmenuButton(
          menuStyle: popupStyle,
          style: _itemButtonStyle(item),
          menuChildren: _buildMenuItems(item.submenuItems ?? [], popupStyle),
          child: _buildItemContent(item),
        );
      }

      return MenuItemButton(
        style: _itemButtonStyle(item),
        onPressed: item.onTap,
        child: _buildItemContent(item),
      );
    }).toList();
  }

  ButtonStyle _itemButtonStyle(CustomMenubarItem item) {
    return ButtonStyle(
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0)),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0))),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
          return item.isDestructive ? Colors.red.withOpacity(0.15) : Colors.white12;
        }
        return Colors.transparent;
      }),
    );
  }

  Widget _buildItemContent(CustomMenubarItem item) {
    final textColor = item.isDestructive ? Colors.red[400] : Colors.white;
    
    return SizedBox(
      width: 200, // min-w-[12rem] structural match
      child: Row(
        children: [
          // Checkbox or Icon slot
          SizedBox(
            width: 28,
            child: item.type == MenubarItemType.checkbox
                ? Icon(item.checked ? Icons.check : null, size: 16, color: Colors.white)
                : (item.icon != null ? Icon(item.icon, size: 16, color: textColor) : null),
          ),
          const SizedBox(width: 4),
          // Label
          Expanded(
            child: Text(
              item.label ?? '',
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
          // Keyboard Shortcut Trailer
          if (item.shortcut != null) ...[
            const SizedBox(width: 8),
            Text(
              item.shortcut!,
              style: const TextStyle(fontSize: 12, color: Colors.white38, letterSpacing: 1.2),
            ),
          ],
          // Submenu arrow indicator
          if (item.type == MenubarItemType.submenu)
            const Icon(Icons.chevron_right, size: 16, color: Colors.white54),
        ],
      ),
    );
  }
}