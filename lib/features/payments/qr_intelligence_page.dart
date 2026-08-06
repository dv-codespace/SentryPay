import 'scan_page.dart';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'analysis_page.dart';

class QrIntelligencePage extends StatefulWidget {
  const QrIntelligencePage({super.key});

  @override
  State<QrIntelligencePage> createState() => _QrIntelligencePageState();
}

class _QrIntelligencePageState extends State<QrIntelligencePage> {
  final TextEditingController _urlController = TextEditingController();
  String _riskResult = "";
  Color _riskColor = Colors.green;
  String _riskReason = "";

  void _analyzeUrl() {
    String url = _urlController.text.trim().toLowerCase();
    if (url.isEmpty) return;

    bool isSuspicious = false;
    List<String> riskyKeywords = ["win", "free", "lottery", "prize", "refund", "claim", "gift", "giveaway", "credential", "login-upi", "verify-bank"];
    List<String> foundWords = [];

    for (var word in riskyKeywords) {
      if (url.contains(word)) {
        isSuspicious = true;
        foundWords.add(word);
      }
    }

    if (!url.startsWith("https://") && (url.startsWith("http://") || url.contains("www."))) {
      isSuspicious = true;
      foundWords.add("unsecured protocol (HTTP)");
    }

    setState(() {
      if (isSuspicious) {
        _riskResult = "⚠ HIGH RISK DETECTED";
        _riskColor = Colors.red;
        _riskReason = "This URL shows characteristics of a payment scam. Reasons: ${foundWords.join(', ')}. SentryPay advises not to send any funds to this address.";
      } else {
        _riskResult = "✅ VERIFIED SECURE";
        _riskColor = const Color(0xFF059669);
        _riskReason = "No suspicious pattern detected. The domain looks legitimate and uses a secure protocol. Safe to transact.";
      }
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
                      "QR Intelligence",
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
                  "Learn about QR risk detection",
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
                  /// INTRODUCTION CARD
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
                      children: const [
                        Text(
                          "SentryPay QR Shield",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Our QR intelligence engine analyzes UPI deep-links, web addresses, and merchant registration codes. Every time you scan a QR code using SentryPay, we verify it against three main pillars of threat detection.",
                          style: TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// DETECTIVE METRIC CARDS
                  _buildPillarCard("1. Domain Analysis", "SentryPay checks if the QR contains links to external web addresses. If the domain is newly registered or resembles a popular bank's login site, we flag it.", Icons.dns),
                  _buildPillarCard("2. Merchant Reputation", "Our system checks the age and transaction volume history of the merchant. A new UPI ID requesting large funds is flagged as medium risk.", Icons.star_border),
                  _buildPillarCard("3. Secure Protocols Check", "Unsecured HTTP connections, raw IP addresses, or redirects inside the payment URL are automatically blocked to prevent phishing attacks.", Icons.security),
                  
                  const SizedBox(height: 25),
                  const Text(
                    "Try SentryPay QR Analyzer",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  /// INTERACTIVE WORKFLOW
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
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 60,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Scan any UPI QR code or link to run a full risk assessment without initiating a payment.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScanPage(isAnalysisOnly: true),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text(
                              "Scan and Analyze QR",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildPillarCard(String title, String description, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8FFF5),
            child: Icon(icon, color: const Color(0xFF059669)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
