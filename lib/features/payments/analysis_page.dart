import 'payment_page.dart';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/data/app_data.dart';
import '../../models/fraud_log.dart';
import 'intent_verification_page.dart';
import 'liveness_page.dart';
import 'success_page.dart';

class AnalysisPage extends StatefulWidget {
  final String qrData;
  final bool isAnalysisOnly;

  const AnalysisPage({super.key, required this.qrData, this.isAnalysisOnly = false});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {

  int riskScore = 0;
  String riskLevel = "";
  Color riskColor = Colors.green;
  String riskReason = "";

  @override
  void initState() {
    super.initState();
    analyzeQR();
  }

  Future<void> analyzeQR() async {

  try {

    final response = await http.post(

      // CHANGE THIS IP
      Uri.parse("https://sentrypay.onrender.com/analyze"),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "url": widget.qrData,
      }),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      lastTransactionContext = {
        "risk_score": data["risk_score"] ?? 0,
        "risk_level": data["risk_level"] ?? "LOW",
        "reasons": data["reasons"] as List? ?? [],
        "url": widget.qrData,
        "intent_result": null,
        "scam_result": null,
        "liveness_active": false,
      };

      riskScore = data["risk_score"] ?? 0;

      riskReason = (data["reasons"] as List)
          .join("\n• ");

      if (riskReason.isEmpty) {
        riskReason = "No suspicious activity detected";
      }

      if (riskScore > 75) {

        riskLevel = "HIGH RISK";
        riskColor = Colors.red;

        setState(() {});

        if (widget.isAnalysisOnly) return;

        showHighRisk();

      } else if (riskScore > 40) {

        riskLevel = "MEDIUM RISK";
        riskColor = Colors.orange;

        setState(() {});

        if (widget.isAnalysisOnly) return;

        final rawReasonsList = data["reasons"] as List? ?? [];
        final List<String> reasonsList = rawReasonsList.map((e) => e.toString()).toList();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IntentVerificationPage(
              qrData: widget.qrData,
              riskScore: riskScore,
              riskLevel: riskLevel,
              riskReason: riskReason,
              reasonsList: reasonsList,
            ),
          ),
        );

      } else {

        riskLevel = "LOW RISK";
        riskColor = Colors.green;

        setState(() {});

        if (widget.isAnalysisOnly) return;

        goToPayment();
      }

    } else {

      riskScore = 100;
      riskLevel = "HIGH RISK";
      riskColor = Colors.red;

      riskReason =
          "Unable to verify QR through Risk Engine";

      setState(() {});
    }

  } catch (e) {

    riskScore = 100;

    riskLevel = "HIGH RISK";

    riskColor = Colors.red;

    riskReason =
        "Risk Engine connection failed.\n$e";

    setState(() {});
  }
}
  /// 🧠 AI Explanation Logic
  String getRiskReason(String qrData, int riskScore) {

    List<String> reasons = [];

    if (qrData.contains("scam")) {
      reasons.add("Suspicious QR source detected");
    }

    if (riskScore > 75) {
      reasons.add("High-risk transaction pattern");
    }

    if (qrData.contains("unknown")) {
      reasons.add("Unverified receiver");
    }

    if (riskScore > 40 && riskScore <= 75) {
      reasons.add("Moderate risk behavior observed");
    }

    if (reasons.isEmpty) {
      reasons.add("No suspicious activity detected");
    }

    return reasons.join("\n• ");
  }

  void showHighRisk() {
    fraudHistory.add(
      FraudLog(
        reason: riskReason,
        riskScore: riskScore,
        time: TimeOfDay.now().format(context),
      ),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠ Scam Alert"),
        content: Text(
          "Risk Score: $riskScore%\n\n⚠ Reason:\n• $riskReason\n\nTransaction Blocked.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              transactionHistory.add({
                "title": "Blocked Payment",
                "name": "Suspicious Merchant",
                "number": widget.qrData,
                "amount": "- ₹0.00",
                "status": "BLOCKED",
                "date": "Today, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
              });
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void showMediumRisk() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠ Warning"),
        content: Text(
          "Risk Score: $riskScore%\n\n⚠ Reason:\n• $riskReason\n\nProceed carefully.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              goToPayment();
            },
            child: const Text("Proceed"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void goToPayment() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          qrData: widget.qrData,
          riskScore: riskScore,
          receiverName: "Scanned Merchant", // ✅ IMPORTANT FIX
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.isAnalysisOnly
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (riskLevel.isEmpty) ...[
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 24),
                      const Text(
                        "Analyzing Transaction QR...",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ] else ...[
                      Icon(
                        riskScore > 75
                            ? Icons.dangerous
                            : (riskScore > 40 ? Icons.warning : Icons.verified),
                        color: riskColor,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        riskLevel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Threat Score: $riskScore%",
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "QR Content / Data:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              widget.qrData,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Risk Assessment Reasons:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              riskReason,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Done / Back to QR Shield",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const CircularProgressIndicator(color: Colors.green),

                  const SizedBox(height: 20),

                  const Text(
                    "Analyzing Transaction...",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Risk Score: $riskScore%",
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    riskLevel,
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 AI Explanation UI
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "⚠ Reason:\n $riskReason",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
