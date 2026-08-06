import '../fraud_prevention/scam_detection_page.dart';
import '../payments/qr_intelligence_page.dart';
import '../fraud_prevention/fraud_alerts_page.dart';
import '../fraud_prevention/security_tips_page.dart';
import 'about_sentrypay_page.dart';

import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

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

            padding: const EdgeInsets.only(
              top: 55,
              left: 20,
              right: 20,
            ),

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
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),

            child: const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                Text(
                  "More",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Security tools and extra features",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [

                  moreTile(
                    context,
                    Icons.security,
                    "Scam Check",
                    "Check suspicious messages and links",
                    const ScamDetectionPage(),
                  ),

                  moreTile(
                    context,
                    Icons.qr_code_scanner,
                    "QR Intelligence",
                    "Learn about QR risk detection",
                    const QrIntelligencePage(),
                  ),

                  moreTile(
                    context,
                    Icons.warning_amber,
                    "Fraud Alerts",
                    "Latest scam awareness",
                    const FraudAlertsPage(),
                  ),

                  moreTile(
                    context,
                    Icons.tips_and_updates,
                    "Security Tips",
                    "Stay protected from fraud",
                    const SecurityTipsPage(),
                  ),

                  moreTile(
                    context,
                    Icons.info_outline,
                    "About SentryPay",
                    "Version & project information",
                    const AboutSentryPayPage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


Widget moreTile(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  Widget? page,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),

    decoration: const BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),

    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8FFF5),

          child: Icon(
            icon,
            color: const Color(0xFF059669),
          ),
        ),

        title: Text(title),

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.chevron_right,
        ),

        onTap: () {

          if (page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => page,
              ),
            );
          }
        },
      ),
    ),
  );
}

