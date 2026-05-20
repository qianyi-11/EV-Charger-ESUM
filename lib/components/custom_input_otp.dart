import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomInputOTP extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final int? separatorAt; // Optional: index after which to show a dash (e.g., 3 for 123-456)

  const CustomInputOTP({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.separatorAt,
  });

  @override
  State<CustomInputOTP> createState() => _CustomInputOTPState();
}

class _CustomInputOTPState extends State<CustomInputOTP> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    
    // Listen to text changes to rebuild the UI slots
    _controller.addListener(() {
      if (mounted) setState(() {});
      if (widget.onChanged != null) {
        widget.onChanged!(_controller.text);
      }
      if (_controller.text.length == widget.length && widget.onCompleted != null) {
        widget.onCompleted!(_controller.text);
      }
    });
    
    // Listen to focus changes to show/hide the blinking caret
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tapping anywhere focuses the hidden text field and brings up the keyboard
      onTap: () => FocusScope.of(context).requestFocus(_focusNode),
      child: SizedBox(
        height: 48,
        child: Stack(
          children: [
            // 1. The visual representation (Shadcn aesthetic slots)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.length, (index) {
                return Row(
                  children: [
                    _buildSlot(index),
                    if (widget.separatorAt != null && 
                        index == widget.separatorAt! - 1 && 
                        index != widget.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.remove, color: Colors.white54, size: 16),
                      ),
                  ],
                );
              }),
            ),
            
            // 2. The invisible logical engine overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  // Natively handles iOS/Android OTP SMS suggestions!
                  autofillHints: const [AutofillHints.oneTimeCode], 
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(int index) {
    final text = _controller.text;
    final char = index < text.length ? text[index] : "";
    final isActive = _focusNode.hasFocus && index == text.length;
    
    // Logic to replicate Shadcn's joined borders
    bool isFirstGroup = index == 0 || (widget.separatorAt != null && index == widget.separatorAt);
    bool isLastGroup = index == widget.length - 1 || (widget.separatorAt != null && index == widget.separatorAt! - 1);

    return Container(
      width: 40,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate input background
        border: Border(
          top: BorderSide(color: isActive ? Colors.white : Colors.white12, width: isActive ? 2 : 1),
          bottom: BorderSide(color: isActive ? Colors.white : Colors.white12, width: isActive ? 2 : 1),
          right: BorderSide(color: isActive ? Colors.white : Colors.white12, width: isActive ? 2 : 1),
          // Only the first box in a group gets a left border, unless a box is active and needs a full ring
          left: BorderSide(color: isActive ? Colors.white : Colors.white12, width: (isFirstGroup || isActive) ? (isActive ? 2 : 1) : 0),
        ),
        borderRadius: BorderRadius.horizontal(
          left: isFirstGroup ? const Radius.circular(6.0) : Radius.zero,
          right: isLastGroup ? const Radius.circular(6.0) : Radius.zero,
        ),
      ),
      child: isActive
          ? const _BlinkingCaret()
          : Text(
              char,
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
            ),
    );
  }
}

/// A simple custom widget to replicate the Shadcn "animate-caret-blink" utility
class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret();

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600)
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 1.5, height: 20, color: Colors.white),
    );
  }
}