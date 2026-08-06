import 'package:flutter/material.dart';
import 'details_collection_page.dart';

class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  bool _otpRequired = true;
  bool _smsAlerts = true;
  bool _whatsappAlerts = false;

  void _changePhoneNumber() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Change Phone Number"),
        content: const Text("To request a change of registered mobile number, please verify with an OTP sent to your email or contact SentryPay support."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Color(0xFF059669))),
          ),
        ],
      ),
    );
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
                      "Phone Number",
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
                  "Registered mobile number settings",
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
                  /// PHONE CARD
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
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFE8FFF5),
                              child: Icon(Icons.phone, color: Color(0xFF059669)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "+91 97904 68298",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Primary Verified Number",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        _buildDetailRow("Verification Status", "Verified", valueColor: const Color(0xFF059669), isVerified: true),
                        _buildDetailRow("Registered On", "August 15, 2025"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// SECURITY SETTINGS CARD
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
                          "Security & OTP Settings",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("High-Value Payment OTP"),
                          subtitle: const Text("Require SMS OTP for transactions above ₹10,000"),
                          value: _otpRequired,
                          onChanged: (val) {
                            setState(() {
                              _otpRequired = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("SMS Activity Alerts"),
                          subtitle: const Text("Receive instant SMS for every transaction activity"),
                          value: _smsAlerts,
                          onChanged: (val) {
                            setState(() {
                              _smsAlerts = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("WhatsApp Fraud Alerts"),
                          subtitle: const Text("Receive alert messages on WhatsApp when suspect activity is noticed"),
                          value: _whatsappAlerts,
                          onChanged: (val) {
                            setState(() {
                              _whatsappAlerts = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _changePhoneNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Change Registered Number"),
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Row(
            children: [
              if (isVerified) ...[
                const Icon(Icons.verified, color: Color(0xFF059669), size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
