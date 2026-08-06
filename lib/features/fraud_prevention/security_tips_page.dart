import '../../core/widgets/smooth_tap.dart';
import 'package:flutter/material.dart';

class SecurityTipsPage extends StatefulWidget {
  const SecurityTipsPage({super.key});

  @override
  State<SecurityTipsPage> createState() => _SecurityTipsPageState();
}

class _SecurityTipsPageState extends State<SecurityTipsPage> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  int _score = 0;

  final List<Map<String, dynamic>> _quizQuestions = [
    {
      "question": "When receiving money via UPI, do you need to enter your UPI PIN?",
      "options": [
        "Yes, to confirm receipt.",
        "No, PIN is only needed to send money.",
        "Only if the amount is above ₹5,000."
      ],
      "correctIndex": 1,
      "explanation": "Correct! You never need to enter your UPI PIN to receive money. If someone asks you to enter your PIN to claim money, it is a scam!"
    },
    {
      "question": "An unknown sender claims they sent you money by mistake and asks you to pay it back. What should you do?",
      "options": [
        "Send it back immediately to be polite.",
        "Ignore them and ask them to coordinate with their bank.",
        "Keep the money and block them."
      ],
      "correctIndex": 1,
      "explanation": "Correct! Coordinates of the transaction must be settled officially through banks to prevent money mules or chargeback scams."
    },
    {
      "question": "What is the best way to contact SentryPay Customer Support?",
      "options": [
        "Google the support number online.",
        "Use the support details in the official app.",
        "Post on Twitter/X asking for help."
      ],
      "correctIndex": 1,
      "explanation": "Correct! Google maps or Twitter/X listings are frequently infested with fake helpline numbers. Always use official in-app contacts."
    }
  ];

  void _answerQuestion(int index) {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == _quizQuestions[_currentQuestionIndex]["correctIndex"]) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _quizQuestions.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _isAnswered = false;
      } else {
        _currentQuestionIndex = _quizQuestions.length;
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _isAnswered = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Security Tips",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Stay protected from digital fraud",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// SECURITY RULES LIST CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Crucial Rules of Safety",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                        const SizedBox(height: 15),
                        _buildTipRow(Icons.pin, "Never Share UPI PIN", "SentryPay or banks will never call and ask you for your PIN, OTP, or passwords."),
                        _buildTipRow(Icons.phonelink_erase, "Avoid Remote Apps", "Do not download screen sharing apps (e.g. AnyDesk, TeamViewer) at the request of anyone claiming to help."),
                        _buildTipRow(Icons.drive_file_rename_outline, "Verify Merchant Name", "Before typing your PIN in a transaction, read the verified merchant name displayed on the screen."),
                        _buildTipRow(Icons.mark_email_unread, "Beware of Suspicious Links", "Double check link addresses. Avoid payment clicks sent via WhatsApp or SMS."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "SentryPay Security Quiz",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  /// INTERACTIVE QUIZ CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildQuizContent(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    if (_currentQuestionIndex >= _quizQuestions.length) {
      return Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 50),
          const SizedBox(height: 12),
          const Text("Quiz Finished!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "You scored $_score / ${_quizQuestions.length}",
            style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const Text(
            "Knowledge is your best armor against payment scams. Keep Sentry Shield active!",
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.3),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _resetQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Restart Quiz"),
            ),
          )
        ],
      );
    }

    var q = _quizQuestions[_currentQuestionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Question ${_currentQuestionIndex + 1}/${_quizQuestions.length}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            Text("Score: $_score", style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Text(q["question"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ...List.generate(q["options"].length, (idx) {
          Color btnColor = Colors.white;
          Color borderClr = Colors.grey[300]!;
          Color textClr = Colors.black87;

          if (_isAnswered) {
            if (idx == q["correctIndex"]) {
              btnColor = const Color(0xFFD1FAE5);
              borderClr = const Color(0xFF34D399);
              textClr = const Color(0xFF065F46);
            } else if (idx == _selectedAnswerIndex) {
              btnColor = const Color(0xFFFEE2E2);
              borderClr = const Color(0xFFF87171);
              textClr = const Color(0xFF991B1B);
            }
          }

          return SmoothTap(
            onTap: () => _answerQuestion(idx),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderClr),
              ),
              child: Text(q["options"][idx], style: TextStyle(color: textClr, fontWeight: FontWeight.w500)),
            ),
          );
        }),
        if (_isAnswered) ...[
          const SizedBox(height: 10),
          Text(q["explanation"], style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_currentQuestionIndex == _quizQuestions.length - 1 ? "Finish Quiz" : "Next Question"),
            ),
          )
        ]
      ],
    );
  }

  Widget _buildTipRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF059669), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
