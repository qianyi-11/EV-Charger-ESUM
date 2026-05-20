import 'package:flutter/material.dart';

class CustomTabs extends StatelessWidget {
  final List<String> titles;
  final List<Widget> children;

  const CustomTabs({
    super.key,
    required this.titles,
    required this.children,
  }) : assert(titles.length == children.length, "Titles and children must have same length");

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: titles.length,
      child: Column(
        children: [
          // The TabsList (pill-shaped container)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white12, // bg-muted
              borderRadius: BorderRadius.circular(12), // rounded-xl
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFF020817), // bg-card
                borderRadius: BorderRadius.circular(9), // rounded-lg
              ),
              labelColor: Colors.white, // Active text color
              unselectedLabelColor: Colors.white60, // Muted text color
              tabs: titles.map((t) => Tab(text: t)).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // The TabsContent
          Expanded(
            child: TabBarView(children: children),
          ),
        ],
      ),
    );
  }
}