import 'package:flutter/material.dart';

class CustomNavigationMenuLink {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const CustomNavigationMenuLink({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });
}

class CustomNavigationMenuItem {
  final String triggerTitle;
  final List<CustomNavigationMenuLink> links;

  const CustomNavigationMenuItem({
    required this.triggerTitle,
    required this.links,
  });
}

class CustomNavigationMenu extends StatefulWidget {
  final List<CustomNavigationMenuItem> items;

  const CustomNavigationMenu({super.key, required this.items});

  @override
  State<CustomNavigationMenu> createState() => _CustomNavigationMenuState();
}

class _CustomNavigationMenuState extends State<CustomNavigationMenu> {
  // Track which menu index is currently open to handle state changes
  int? _openMenuIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.items.asMap().entries.map((entry) {
        final int index = entry.key;
        final CustomNavigationMenuItem item = entry.value;
        final bool isOpen = _openMenuIndex == index;

        return PopupMenuButton<CustomNavigationMenuLink>(
          color: const Color(0xFF0F172A), // bg-popover / Dark slate panel
          elevation: 4,
          offset: const Offset(0, 42), // Moves content container below the trigger row
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0), // rounded-md
            side: const BorderSide(color: Colors.white12, width: 1.0), // border
          ),
          onOpened: () => setState(() => _openMenuIndex = index),
          onCanceled: () => setState(() => _openMenuIndex = null),
          onSelected: (link) {
            setState(() => _openMenuIndex = null);
            link.onTap();
          },
          // Trigger style matching navigationMenuTriggerStyle code block
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 36, // h-9
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isOpen ? Colors.white12 : Colors.transparent, // navigationMenuTriggerStyle states
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.triggerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // text-sm
                    fontWeight: FontWeight.w500, // font-medium
                  ),
                ),
                const SizedBox(width: 4),
                // Smooth chevron animation mimicking the 300ms group-data-[state=open]:rotate-180 logic
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0.0, // Rotates exactly 180 degrees
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          itemBuilder: (context) {
            return item.links.map((link) {
              return PopupMenuItem<CustomNavigationMenuLink>(
                value: link,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  width: 240, // Emulates structural layout constraints (md:w-auto / min-w)
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            link.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (link.trailing != null) link.trailing!,
                        ],
                      ),
                      if (link.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          link.subtitle!,
                          style: const TextStyle(
                            color: Colors.white38, // text-muted-foreground
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList();
          },
        );
      }).toList(),
    );
  }
}