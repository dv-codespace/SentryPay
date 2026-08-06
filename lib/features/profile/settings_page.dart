import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firestore_service.dart';
import '../../features/auth/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricAuth = true;
  bool _sentryShield = true;
  bool _blockSuspicious = true;
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  double _dailyLimit = 50000;

  void _savePreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Preferences saved successfully"),
        backgroundColor: Color(0xFF059669),
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
                      "Settings",
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
                  "Security, notifications & preferences",
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
                  /// SECURITY SETTINGS
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
                          "Security Settings",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Biometric Login"),
                          subtitle: const Text("Use fingerprint or face recognition to unlock"),
                          value: _biometricAuth,
                          onChanged: (val) {
                            setState(() {
                              _biometricAuth = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Enable Sentry Shield"),
                          subtitle: const Text("Real-time transaction threat analysis"),
                          value: _sentryShield,
                          onChanged: (val) {
                            setState(() {
                              _sentryShield = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Block Suspicious Merchants"),
                          subtitle: const Text("Automatically block transactions to high-risk receivers"),
                          value: _blockSuspicious,
                          onChanged: (val) {
                            setState(() {
                              _blockSuspicious = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// TRANSACTION LIMIT
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Daily Limit",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "₹${_dailyLimit.toInt().toString()}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Slider(
                          activeColor: const Color(0xFF059669),
                          inactiveColor: const Color(0xFFE8FFF5),
                          min: 5000,
                          max: 100000,
                          divisions: 19,
                          label: "₹${_dailyLimit.toInt()}",
                          value: _dailyLimit,
                          onChanged: (val) {
                            setState(() {
                              _dailyLimit = val;
                            });
                          },
                        ),
                        const Text(
                          "Drag slider to set your maximum daily outbound payment limit.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  /// NOTIFICATIONS
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
                          "Notification Preferences",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Push Notifications"),
                          subtitle: const Text("Instant payment alerts and security updates"),
                          value: _pushNotifications,
                          onChanged: (val) {
                            setState(() {
                              _pushNotifications = val;
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          activeColor: const Color(0xFF059669),
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Email Alerts"),
                          subtitle: const Text("Weekly summary reports and news"),
                          value: _emailAlerts,
                          onChanged: (val) {
                            setState(() {
                              _emailAlerts = val;
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
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Save Preferences"),
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
}
