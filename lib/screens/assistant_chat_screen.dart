import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/pulsing_glow.dart';
import '../services/ml_model_service.dart';
import '../models/diagnostic_state.dart';


class MessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  MessageModel({required this.text, required this.isUser, required this.timestamp});
}

class AssistantChatScreen extends StatefulWidget {
  final bool embeddedInShell;

  const AssistantChatScreen({super.key, this.embeddedInShell = false});

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final List<MessageModel> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isAiTyping = false;
  bool _showSuggestions = true;

  // Preset Q&A aligned with the EVision diagnosis flow
  final Map<String, String> _knowledgeBase = {
    'What does a red blinking light mean?':
        'A red blinking status light is a fault code. Use Step 3 (Record Blink Pattern) in the diagnosis flow — we count the blinks and match them to faults such as earth loop, E-stop, leakage protection, or controller lock.',
    'My charger has no power — what should I check?':
        'Confirm the wall isolator switch is ON. If the status light is completely off, run Start Diagnosis — we guide you to photograph the isolator and EV distribution board (EVDB) to find whether power is cut or a breaker issue exists.',
    'How do I start a diagnosis?':
        'From the Dashboard tap Start Diagnosis. Step 1 scans your charger label, Step 2 checks the status light, then we branch into power checks or blink recording depending on what we detect.',
    'When should I create a support ticket?':
        'Create a ticket after diagnosis if you need RExharge after-sales help — especially for EVDB/protection issues, persistent faults, or when on-site service is recommended. Your scan results and photos are attached automatically.',
  };

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(
      MessageModel(
        text: "Hello! I am your EVision AI technical diagnostic assistant. I have loaded the telemetry metrics for the active charger. How can I help you resolve this issue?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    // Capture user query
    final userMsg = MessageModel(text: text, isUser: true, timestamp: DateTime.now());

    setState(() {
      _messages.add(userMsg);
      _showSuggestions = false;
      _isAiTyping = true;
    });

    _scrollToBottom();
    _inputController.clear();

    // Local pre-check in the knowledge base (case-insensitive & ignoring punctuation)
    final String trimmedText = text.trim();
    String? matchedKnowledge;

    for (final entry in _knowledgeBase.entries) {
      final keyClean = entry.key.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      final textClean = trimmedText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      if (keyClean == textClean) {
        matchedKnowledge = entry.value;
        break;
      }
    }

    if (matchedKnowledge != null) {
      // Simulate quick typing delay for a premium fluid experience
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _isAiTyping = false;
          _messages.add(MessageModel(
            text: matchedKnowledge!,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      });
      return;
    }

    // Map history to server schema format
    final historyJson = _messages
        .take(_messages.length - 1) // Exclude the new user message from history itself
        .map((m) => {
              "isUser": m.isUser,
              "text": m.text,
            })
        .toList();

    // Query technical chat engine dynamically
    final mlService = MlModelService();
    mlService.chatWithAi(text, historyJson).then((response) {
      if (!mounted) return;
      setState(() {
        _isAiTyping = false;
        _messages.add(MessageModel(text: response, isUser: false, timestamp: DateTime.now()));
      });
      _scrollToBottom();
    }).catchError((err) {
      if (!mounted) return;
      setState(() {
        _isAiTyping = false;
        // Never bubble up raw connection errors in production UI; use the stable fallback response
        _messages.add(MessageModel(
          text: mlService.fallbackResponse(text),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptive;

    return Scaffold(
      backgroundColor: adaptive.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.embeddedInShell,
        leading: widget.embeddedInShell
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: adaptive.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Row(
          children: [
            PulsingGlow(
              glowColor: AppColors.successGreen,
              minBlurRadius: 4,
              maxBlurRadius: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "EVision AI Assistant",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: adaptive.textPrimary),
                ),
                Text(
                  "System Engineer Bot • Online",
                  style: TextStyle(fontSize: 10, color: adaptive.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat bubble list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Typing Indicator
            if (_isAiTyping) _buildTypingIndicator(),

            // Suggested prompt grid on startup
            if (_showSuggestions) _buildSuggestionsGrid(),

            // Bottom Input Bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg) {
    final bool isUser = msg.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              bgColor: isUser ? AppColors.electricBlue.withOpacity(0.12) : AppColors.secondaryBg.withOpacity(0.6),
              borderColor: isUser ? AppColors.electricBlue.withOpacity(0.3) : AppColors.glassBorder,
              child: Text(
                msg.text,
                style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DotPulse(delay: 0),
              SizedBox(width: 4),
              _DotPulse(delay: 150),
              SizedBox(width: 4),
              _DotPulse(delay: 300),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsGrid() {
    final List<String> prompts = _knowledgeBase.keys.toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Suggested Questions:",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.8,
            ),
            itemCount: prompts.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _sendMessage(prompts[index]),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Text(
                        prompts[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: Row(
        children: [
          // Voice Mic Button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Voice recognition module initializing... Speak now."),
                  backgroundColor: AppColors.secondaryBg,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.secondaryBg, shape: BoxShape.circle),
              child: const Icon(Icons.mic, color: AppColors.electricBlue, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          
          // Text Input Box
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _inputController,
                onSubmitted: _sendMessage,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Ask me anything...",
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          GestureDetector(
            onTap: () => _sendMessage(_inputController.text),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.electricBlue, Color(0xFF005F80)],
                  ),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotPulse extends StatefulWidget {
  final int delay;

  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_ctrl.value * 0.7),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.electricBlue, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}
