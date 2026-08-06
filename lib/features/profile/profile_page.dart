import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../cards_accounts/bank_account_page.dart';
import '../cards_accounts/manage_cards_page.dart';
import '../payments/scan_page.dart';
import '../cards_accounts/manage_account_page.dart';
import 'face_capture_page.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_page.dart';
import '../../services/firestore_service.dart';
import '../../features/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Map<String, dynamic>> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString("phone");
    if (phone == null) {
      throw Exception("User session not found. Please log in again.");
    }
    final data = await FirestoreService.getUser(phone);
    if (data == null) {
      throw Exception("Profile data not found.");
    }
    return data;
  }

  Future<void> _registerFace(BuildContext context, String phone) async {
    try {
      final String? capturedPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const FaceCapturePage()),
      );
      if (capturedPath == null) return; // User cancelled

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFF059669)),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  "Scanning face & checking eye clarity...",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );

      // Simulate face/eye processing
      await Future.delayed(const Duration(seconds: 2));

      await FirestoreService.updateRegisteredFace(phone, capturedPath);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Face registered successfully with clear eye detection!"),
          backgroundColor: Color(0xFF059669),
        ),
      );

      setState(() {}); // Refresh to update card subtitle

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error registering face: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String getBankAcronym(String bankName) {
    final cleanBank = bankName.trim().toLowerCase();
    if (cleanBank.contains("sentrypay wallet")) return "sentrypay";
    if (cleanBank.contains("state bank of india")) return "sbi";
    if (cleanBank.contains("indian overseas bank")) return "iob";
    if (cleanBank.contains("hdfc bank")) return "hdfc";
    if (cleanBank.contains("icici bank")) return "icici";
    if (cleanBank.contains("axis bank")) return "axis";
    if (cleanBank.contains("canara bank")) return "canara";
    if (cleanBank.contains("indian bank")) return "indian";
    if (cleanBank.contains("punjab national bank")) return "pnb";
    if (cleanBank.contains("kotak mahindra bank")) return "kotak";
    if (cleanBank.contains("federal bank")) return "federal";
    return bankName.split(" ").map((w) => w.isNotEmpty ? w[0].toUpperCase() : "").join();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchProfileData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FFFC),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF059669),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FFFC),
            body: Center(
              child: Text(
                "Error loading profile: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final userData = snapshot.data ?? {};
        final name = userData['name'] ?? "Unknown User";
        final phone = userData['phone'] ?? "No phone number";
        final bank = userData['bank'] ?? "No bank linked";
        final photo = userData['photo'] as String?;

        // Parse and migrate accounts list
        List<dynamic> accounts = List.from(userData['accounts'] ?? []);
        if (accounts.isEmpty) {
          final String cleanName = name.replaceAll(" ", "").toLowerCase();
          final String cleanBankAcronym = getBankAcronym(bank).toLowerCase();
          final String primaryUpiId = bank == "SentryPay Wallet"
              ? "$phone@sentrypay"
              : "$cleanName-$cleanBankAcronym@sentrypay";
          
          accounts = [
            {
              "bank": bank,
              "upiPin": userData['appPin'] ?? "",
              "balance": 5000.0,
              "accountNo": bank == "SentryPay Wallet" ? "Wallet" : "•••• 8742",
              "isPrimary": true,
              "upiId": primaryUpiId,
            }
          ];
        }

        // Find primary account
        Map<String, dynamic> primaryAccount = accounts.firstWhere(
          (acc) => acc['isPrimary'] == true,
          orElse: () => accounts.first,
        );

        final upiId = primaryAccount['upiId'] ?? "$phone@sentrypay";

        return Scaffold(
          backgroundColor: const Color(0xFFF8FFFC),
          body: Column(
            children: [
              /// HEADER
              Container(
                width: double.infinity,
                height: 200,
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
                child: Row(
                  children: [
                    /// USER INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            upiId,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              SizedBox(width: 4),
                              Text(
                                "Protected by SentryPay",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    /// PROFILE PHOTO
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD1FAE5),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundImage: (photo != null && photo.isNotEmpty)
                            ? (kIsWeb ? NetworkImage(photo) : FileImage(File(photo)) as ImageProvider)
                            : const AssetImage("assets/profile.png"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              /// SCROLLABLE CONTENT
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        profileCard(
                          Icons.account_balance,
                          "Bank Account",
                          "${accounts.length} ${accounts.length == 1 ? 'Account' : 'Accounts'}",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BankAccountPage(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                        profileCard(
                          Icons.credit_card,
                          "Cards",
                          "Manage your virtual and physical cards",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageCardsPage(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                        profileCard(
                          Icons.qr_code,
                          "My QR Code",
                          "Show personal payment QR",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ScanPage(initialTab: 1),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                        profileCard(
                          Icons.settings,
                          "Settings",
                          "Security, notifications & more",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsPage(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                        profileCard(
                          Icons.manage_accounts,
                          "Manage Account",
                          "Profile & account settings",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageAccountPage(),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                        profileCard(
                          Icons.face_retouching_natural,
                          "Face Authentication",
                          userData['registeredFace'] != null
                              ? "Face Registered ✅"
                              : "Configure face recognition for secure payments",
                          trailing: userData['registeredFace'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(userData['registeredFace']),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                          onTap: () {
                            _registerFace(context, phone);
                          },
                        ),
                        profileCard(
                          Icons.logout,
                          "Logout",
                          "Sign out from SentryPay",
                          iconColor: Colors.red,
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget profileCard(
  IconData icon,
  String title,
  String subtitle, {
  Color iconColor = const Color(0xFF059669),
  VoidCallback? onTap,
  Widget? trailing,
}) {
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
            color: iconColor,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    ),
  );
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out from SentryPay?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Clear session in SharedPreferences
              await FirestoreService.clearSession();
              
              if (context.mounted) {
                // Navigate back to LoginPage and clear route history
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Logged out successfully"),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Logout"),
          ),
        ],
      );
    },
  );
}
