import 'package:flutter/material.dart';

class CustomCommandItem {
  final String label;
  final IconData? icon;
  final String? shortcut;
  final VoidCallback onTap;

  const CustomCommandItem({
    required this.label,
    this.icon,
    this.shortcut,
    required this.onTap,
  });
}

class CustomCommandGroup {
  final String heading;
  final List<CustomCommandItem> items;

  const CustomCommandGroup({
    required this.heading,
    required this.items,
  });
}

class CustomCommandPalette extends StatefulWidget {
  final String hintText;
  final List<CustomCommandGroup> groups;
  final String emptyText;

  const CustomCommandPalette({
    super.key,
    this.hintText = "Search for a command to run...",
    required this.groups,
    this.emptyText = "No results found.",
  });

  @override
  State<CustomCommandPalette> createState() => _CustomCommandPaletteState();
}

class _CustomCommandPaletteState extends State<CustomCommandPalette> {
  final SearchController _searchController = SearchController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // bg-popover / dark mode background
        borderRadius: BorderRadius.circular(8.0), // rounded-md
        border: Border.all(color: Colors.white12), // border
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // CommandInput layer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: Colors.white38),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12), // CommandSeparator
          
          // CommandList container matching max-h-[300px] bounds
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _buildFilteredList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList() {
    List<Widget> listContent = [];
    bool hasAnyMatches = false;

    for (var group in widget.groups) {
      // Filter items according to search text query matching rule
      final matchedItems = group.items.where((item) {
        return item.label.toLowerCase().contains(_searchQuery);
      }).toList();

      if (matchedItems.isNotEmpty) {
        hasAnyMatches = true;
        
        // CommandGroup label header styling
        listContent.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
            child: Text(
              group.heading,
              style: const TextStyle(
                color: Colors.white38, // text-muted-foreground
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

        // CommandItem loops
        for (var item in matchedItems) {
          listContent.add(
            InkWell(
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 16, color: Colors.white70),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      item.label,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    if (item.shortcut != null) ...[
                      const Spacer(),
                      Text(
                        item.shortcut!,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    // CommandEmpty alternative state text feedback render
    if (!hasAnyMatches) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            widget.emptyText,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      children: listContent,
    );
  }
}