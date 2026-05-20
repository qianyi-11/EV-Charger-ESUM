import 'package:flutter/material.dart';

class CustomSelectItem<T> {
  final T value;
  final String label;
  final Widget? icon;

  const CustomSelectItem({required this.value, required this.label, this.icon});
}

class CustomSelect<T> extends StatefulWidget {
  final T? value;
  final List<CustomSelectItem<T>> items;
  final ValueChanged<T> onChanged;
  final String placeholder;

  const CustomSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.placeholder = "Select an option",
  });

  @override
  State<CustomSelect<T>> createState() => _CustomSelectState<T>();
}

class _CustomSelectState<T> extends State<CustomSelect<T>> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.firstWhere(
      (i) => i.value == widget.value,
      orElse: () => CustomSelectItem(value: null as T, label: widget.placeholder),
    );

    return MenuAnchor(
      controller: _menuController,
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
          side: const BorderSide(color: Colors.white12),
        )),
      ),
      menuChildren: widget.items.map((item) {
        return MenuItemButton(
          onPressed: () => widget.onChanged(item.value),
          child: SizedBox(
            width: 200,
            child: Row(
              children: [
                Expanded(child: Text(item.label, style: const TextStyle(color: Colors.white))),
                if (widget.value == item.value) const Icon(Icons.check, size: 16, color: Colors.white),
              ],
            ),
          ),
        );
      }).toList(),
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            height: 36, // h-9
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF020817),
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedItem.label,
                  style: TextStyle(
                    color: widget.value == null ? Colors.white38 : Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white54),
              ],
            ),
          ),
        );
      },
    );
  }
}