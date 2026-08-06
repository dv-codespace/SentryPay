import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/data/app_data.dart';
import '../../core/config/secrets.dart';
import 'dart:ui';

class SentryChatPage extends StatefulWidget {
  const SentryChatPage({super.key});

  @override
  State<SentryChatPage> createState() => _SentryChatPageState();
}

class _SentryChatPageState extends State<SentryChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      "role": "sentry",
      "content": "Hi, I'm Sentry AI. I monitor your transactions and guide you on digital payment security. How can I help you today?",
      "time": DateTime.now().toLocal().toString().substring(11, 16),
    }
  ];
  bool _isLoading = false;

  final List<String> _suggestions = [
    "Is my QR safe?",
    "Why is this payment risky?",
    "Explain Risk Score.",
    "What is QR phishing?",
    "How does Intent Verification work?",
    "Why do I need Face Verification?",
    "Safe payment tips.",
    "Common QR scams.",
    "Report suspicious activity.",
    "Help me understand this transaction."
  ];

  late final GenerativeModel _aiModel;
  late ChatSession _aiChat;

  @override
  void initState() {
    super.initState();
    
    // Initialize Gemini model via Google Generative AI directly using Developer API Key
    _aiModel = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: geminiApiKey,
      systemInstruction: Content.system(
        "Identity: You are Sentry, the intelligent security companion inside the SentryPay application. "
        "Your purpose is to educate, guide, and explain. You never approve payments, never override security modules, "
        "and never fabricate information. When available, base your answers on the outputs of the Risk Engine, "
        "Scam Language Detection, Intent Verification AI, and Liveness Authentication. "
        "If context is unavailable, clearly state that you're providing general guidance. "
        "IMPORTANT: Always keep your responses highly concise, direct, and under 2-3 sentences. Avoid long explanations."
      ),
    );
    _aiChat = _aiModel.startChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = {
      "role": "user",
      "content": text,
      "time": DateTime.now().toLocal().toString().substring(11, 16),
    };

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Include current transaction context if available to help the agent give context-aware tips
      final promptText = lastTransactionContext.isNotEmpty
          ? "System Context: $lastTransactionContext\nUser message: $text"
          : text;

      final response = await _aiChat.sendMessage(Content.text(promptText));
      final reply = response.text ?? "I couldn't process that request.";

      setState(() {
        _messages.add({
          "role": "sentry",
          "content": reply,
          "time": DateTime.now().toLocal().toString().substring(11, 16),
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "sentry",
          "content": "Error calling Sentry AI: ${e.toString()}",
          "time": DateTime.now().toLocal().toString().substring(11, 16),
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _clearChat() {
    setState(() {
      // Restart the chat session to clear Gemini's short-term history
      _aiChat = _aiModel.startChat();
      _messages.clear();
      _messages.add({
        "role": "sentry",
        "content": "Hi, I'm Sentry AI. I monitor your transactions and guide you on digital payment security. How can I help you today?",
        "time": DateTime.now().toLocal().toString().substring(11, 16),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC), // Light Mode Background
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome, 
                color: Colors.white, 
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Sentry AI", 
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified, color: Colors.white.withOpacity(0.9), size: 14),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Active Guardian", 
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF059669),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: "Clear Chat",
            onPressed: _clearChat,
          )
        ],
      ),
      body: Column(
        children: [

          /// Bubbles View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  /// Typing Indicator
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(16),
                          topLeft: Radius.circular(16),
                        ),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Sentry AI is thinking...",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final m = _messages[index];
                final isUser = m["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF34D399),
                                Color(0xFF059669),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isUser ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: isUser ? const Color(0x3310B981) : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF059669), size: 14),
                              SizedBox(width: 6),
                              Text(
                                "Sentry AI",
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          m["content"],
                          style: TextStyle(
                            color: isUser ? Colors.white : const Color(0xFF0F172A), 
                            fontSize: 14, 
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            m["time"],
                            style: TextStyle(
                              color: isUser ? Colors.white70 : Colors.black26,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// Input Area
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Ask about safety tips, scams...",
                        hintStyle: TextStyle(color: Colors.black38),
                        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) {
                        _sendMessage(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF34D399),
                        Color(0xFF059669),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {
                      _sendMessage(_messageController.text);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
