import '../dashboard/dashboard_page.dart';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../core/data/app_data.dart';
import 'payment_page.dart';

class IntentVerificationPage extends StatefulWidget {
  final String qrData;
  final int riskScore;
  final String riskLevel;
  final String riskReason;
  final List<String> reasonsList;

  const IntentVerificationPage({
    super.key,
    required this.qrData,
    required this.riskScore,
    required this.riskLevel,
    required this.riskReason,
    required this.reasonsList,
  });

  @override
  State<IntentVerificationPage> createState() => _IntentVerificationPageState();
}

class _IntentVerificationPageState extends State<IntentVerificationPage> {
  List<String> questions = [];
  final List<String?> answers = [null, null, null];
  bool isLoading = true;
  bool isSubmitting = false;
  String errorMessage = "";
  Map<String, dynamic>? resultData;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  String getIntentAiUrl() {
    return "https://sentrypay-intent-ai.onrender.com";
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.post(
        Uri.parse("${getIntentAiUrl()}/generate-intent-questions"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "url": widget.qrData,
          "ml_score": 0,
          "rule_score": 0,
          "risk_score": widget.riskScore,
          "risk_level": widget.riskLevel,
          "reasons": widget.reasonsList,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          questions = List<String>.from(data["questions"] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load questions from Intent AI (status: ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection to Intent AI failed.\nMake sure the intent-ai service is running.\n$e";
        isLoading = false;
      });
    }
  }

  Future<void> submitAnswers() async {
    if (answers.contains(null)) {
      setState(() {
        errorMessage = "Please select an answer for all three questions.";
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse("${getIntentAiUrl()}/verify-intent"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "risk_result": {
            "url": widget.qrData,
            "ml_score": 0,
            "rule_score": 0,
            "risk_score": widget.riskScore,
            "risk_level": widget.riskLevel,
            "reasons": widget.reasonsList,
          },
          "questions": questions,
          "answers": answers,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final decision = data["decision"] ?? "BLOCK";
        lastTransactionContext["intent_result"] = decision;
        
        setState(() {
          resultData = data;
          isSubmitting = false;
        });

        if (decision == "SAFE") {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPage(
                qrData: widget.qrData,
                riskScore: widget.riskScore,
                receiverName: "Scanned Merchant",
              ),
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = "Failed to verify intent (status: ${response.statusCode})";
          isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection to Intent AI failed.\n$e";
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildOptionButton(int questionIndex, String optionText) {
    bool isSelected = answers[questionIndex] == optionText;
    Color buttonColor = isSelected ? const Color(0xFF059669) : Colors.white;
    Color textColor = isSelected ? Colors.white : Colors.black87;
    Color borderColor = isSelected ? const Color(0xFF059669) : Colors.grey.shade300;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            answers[questionIndex] = optionText;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: buttonColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              optionText,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (resultData != null && resultData!["decision"] != "SAFE") {
      final reasons = List<String>.from(resultData!["reason"] ?? []);
      final intentScore = resultData!["intent_score"] ?? 0;
      final confidence = resultData!["confidence"] ?? 0.0;

      return Scaffold(
        backgroundColor: const Color(0xFFFFFBEB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 80.0,
                ),
                const SizedBox(height: 24.0),
                const Text(
                  "High Risk Alert",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                Text(
                  "Security Intent Score: $intentScore/100 (Confidence: ${(confidence * 100).toInt()}%)",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12.0),
                const Text(
                  "Warning: SentryPay AI detected potential scam indicators based on your answers. Please review the threat explanation carefully before proceeding.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.08),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Risk Indicators Identified:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      ...reasons.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 40.0),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                qrData: widget.qrData,
                                riskScore: widget.riskScore,
                                receiverName: "Scanned Merchant",
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Proceed to Payment",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const DashboardPage()),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Cancel & Go Back",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      appBar: AppBar(
        title: const Text("Intent Verification"),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
              (route) => false,
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF10B981)),
                  SizedBox(height: 16),
                  Text("Generating Verification Questions..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Transaction Security Verification",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please answer the following three questions to help us verify that you understand the payment you are making.",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ...List.generate(questions.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Question ${index + 1}",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            questions[index],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildOptionButton(index, "Yes"),
                              const SizedBox(width: 8),
                              _buildOptionButton(index, "No"),
                              const SizedBox(width: 8),
                              _buildOptionButton(index, "I don't know"),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: isSubmitting ? null : submitAnswers,
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Verify & Proceed",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
