import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/localization.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<Map<String, String>> messages;
  late List<String> _suggestedQuestions;
  late String _lastLanguage;

  @override
  void initState() {
    super.initState();
    _lastLanguage = AppLocalizations.getLanguage();
    _initializeMessages();
  }

  void _initializeMessages() {
    messages = [
      {"sender": "ai", "text": AppLocalizations.translate('ai_greeting')},
    ];
    _suggestedQuestions = [
      AppLocalizations.translate('error_8'),
      AppLocalizations.translate('dangerous'),
      AppLocalizations.translate('continue_charging'),
      AppLocalizations.translate('how_fix'),
    ];
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": text});
    });

    _controller.clear();

    // Auto-scroll to bottom after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if language has changed and update suggested questions if needed
    final currentLanguage = AppLocalizations.getLanguage();
    if (currentLanguage != _lastLanguage) {
      _lastLanguage = currentLanguage;
      setState(() {
        _suggestedQuestions = [
          AppLocalizations.translate('error_8'),
          AppLocalizations.translate('dangerous'),
          AppLocalizations.translate('continue_charging'),
          AppLocalizations.translate('how_fix'),
        ];
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020817), // Shadcn bg-background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("EVision AI Assistant", style: TextStyle(color: Colors.white)),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF00FF88), size: 10),
                SizedBox(width: 8),
                Text(
                  "Online",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B1F3C), Color(0xFF07101F)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -24,
                    right: -24,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.cyan.withOpacity(0.24),
                            Colors.transparent,
                          ],
                          radius: 0.85,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -16,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00D4FF).withOpacity(0.12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D4FF).withOpacity(0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "EVision AI Assistant",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Your intelligent charger diagnostic assistant.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Ask questions, review system status and get troubleshooting guidance.",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF081626),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 4,
                      margin: const EdgeInsets.only(
                        top: 12,
                        left: 20,
                        right: 20,
                        bottom: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.18,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        thickness: 6.0,
                        radius: const Radius.circular(99.0),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isUser = msg["sender"] == "user";
                            return FadeInUp(
                              duration: const Duration(milliseconds: 400),
                              from: 30,
                              child: Align(
                                alignment: isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? const Color(
                                            0xFF00D4FF,
                                          ).withOpacity(0.16)
                                        : const Color(
                                            0xFFFFFFFF,
                                          ).withOpacity(0.06),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(
                                        isUser ? 20 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isUser ? 4 : 20,
                                      ),
                                    ),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Text(
                                    msg["text"]!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Suggested quick questions (matches the pasted design)
                    if (_suggestedQuestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: _suggestedQuestions.map((q) {
                            return GestureDetector(
                              onTap: () => _sendMessage(q),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF071628),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  q,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), // Shadcn bg-popover
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Ask me anything...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00D4FF)),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
