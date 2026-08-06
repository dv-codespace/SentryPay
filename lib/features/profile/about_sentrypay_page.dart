import 'package:flutter/material.dart';

class AboutSentryPayPage extends StatelessWidget {
  const AboutSentryPayPage({super.key});

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
                      "About SentryPay",
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
                  "Version & developer details",
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
                children: [
                  /// LOGO CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
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
                      children: const [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.transparent,
                          backgroundImage: AssetImage("assets/logo2.png"),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "SentryPay",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Version 1.0.2",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "AI-Powered Secure Payment Guard",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// DESCRIPTION CARD
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
                          "What is SentryPay?",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "SentryPay is an experimental mobile payment application integrated with ML-based risk engines. By evaluating merchant trust metrics, payment link protocols, and potential SMS patterns in real time, SentryPay aims to block fraud before money is lost.",
                          style: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// LEGAL LINKS CARD
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
                          "Legal & Info",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildLegalRow(context, "Terms of Service"),
                        const Divider(),
                        _buildLegalRow(context, "Privacy Policy"),
                        const Divider(),
                        _buildLegalRow(context, "Open Source Licenses"),
                        const Divider(),
                        _buildLegalRow(context, "Contact Support (support@sentrypay.com)"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalRow(BuildContext context, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(title),
            content: Text("Mock content for $title. This information is for demonstration purposes in the SentryPay app."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Color(0xFF059669))),
              ),
            ],
          ),
        );
      },
    );
  }
}
