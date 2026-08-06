import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../payments/upi_pin_page.dart';
import '../onboarding/pin_setup_page.dart';
import '../onboarding/bank_selection_page.dart';
import '../onboarding/new_sentrypay_account_page.dart';
import 'account_details_page.dart';
import '../../core/data/app_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firestore_service.dart';
import 'package:flutter/material.dart';

class BankAccountPage extends StatefulWidget {
  const BankAccountPage({super.key});

  @override
  State<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends State<BankAccountPage> {
  final Map<String, String> _bankLogos = {
    "State Bank of India": "assets/banks/SBI.png",
    "Indian Overseas Bank": "assets/banks/IOB.png",
    "HDFC Bank": "assets/banks/HDFC.png",
    "ICICI Bank": "assets/banks/ICICI.png",
    "Axis Bank": "assets/banks/Axis.png",
    "Canara Bank": "assets/banks/Canara.png",
    "Indian Bank": "assets/banks/Indian Bank.png",
    "Punjab National Bank": "assets/banks/PNB.png",
    "Kotak Mahindra Bank": "assets/banks/Kotak.png",
    "Federal Bank": "assets/banks/Federal.png",
    "SentryPay Wallet": "assets/logo2.png"
  };

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

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString("phone");
    if (phone == null) throw Exception("Session not found");
    final data = await FirestoreService.getUser(phone);
    if (data == null) throw Exception("Profile not found");
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchProfileData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FFFC),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FFFC),
            body: Center(
              child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final userData = snapshot.data ?? {};
        final name = userData['name'] ?? "Unknown User";
        final phone = userData['phone'] ?? "Unknown Phone";
        
        // Parse and migrate accounts list
        List<dynamic> accounts = List.from(userData['accounts'] ?? []);
        if (accounts.isEmpty) {
          final primaryBank = userData['bank'] ?? "SentryPay Wallet";
          final primaryPin = userData['appPin'] ?? "";
          final String cleanName = name.replaceAll(" ", "").toLowerCase();
          final String cleanBankAcronym = getBankAcronym(primaryBank).toLowerCase();
          final String primaryUpiId = primaryBank == "SentryPay Wallet"
              ? "$phone@sentrypay"
              : "$cleanName-$cleanBankAcronym@sentrypay";
          
          accounts = [
            {
              "bank": primaryBank,
              "upiPin": primaryPin,
              "balance": 5000.0,
              "accountNo": primaryBank == "SentryPay Wallet" ? "Wallet" : "•••• 8742",
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

        final primaryUpiId = primaryAccount['upiId'] ?? "$phone@sentrypay";

        // Check if SentryPay Wallet is linked
        final bool hasWallet = accounts.any((acc) => acc['bank'] == "SentryPay Wallet");

        // Helper parameters for redirecting to adding/creating
        final firstName = userData['firstName'] ?? name.split(' ').first;
        final lastName = userData['lastName'] ?? (name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : '');
        final dob = userData['dob'] ?? "01/01/2000";
        final email = userData['email'] ?? "noemail@sentrypay.com";
        final photo = userData['photo'] as String?;

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
                          "Bank Accounts",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Primary UPI ID: $primaryUpiId",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              /// LIST OF CONNECTED BANK ACCOUNTS
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final acc = Map<String, dynamic>.from(accounts[index]);
                    final bankName = acc['bank'] ?? "";
                    final isPrimary = acc['isPrimary'] ?? false;
                    final accountNo = acc['accountNo'] ?? "";
                    final logoPath = _bankLogos[bankName];
                    final isWallet = bankName == "SentryPay Wallet";
                    final accountType = isWallet ? "Digital Wallet" : "Savings Account";

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountDetailsPage(
                              phone: phone,
                              userName: name,
                              account: acc,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isPrimary ? const Color(0xFF059669) : const Color(0xFFD1FAE5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                isWallet
                                    ? Image.asset('assets/logo2.png', width: 44, height: 44, fit: BoxFit.contain)
                                    : (logoPath != null
                                        ? Image.asset(logoPath, width: 44, height: 44, fit: BoxFit.contain)
                                        : const CircleAvatar(
                                            radius: 22,
                                            backgroundColor: Color(0xFFE8FFF5),
                                            child: Icon(Icons.account_balance, color: Color(0xFF059669)),
                                          )),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bankName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$accountType • $accountNo",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            Row(
                              children: [
                                Icon(
                                  isPrimary ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isPrimary ? const Color(0xFF059669) : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isPrimary ? "Primary Account" : "Secondary Account",
                                  style: TextStyle(
                                    color: isPrimary ? const Color(0xFF059669) : Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// BOTTOM ACTION BUTTONS
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (!hasWallet) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewSentryPayAccountPage(
                                  phone: phone,
                                  firstName: firstName,
                                  lastName: lastName,
                                  dob: dob,
                                  email: email,
                                  photo: photo,
                                  isAddAccount: true,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          icon: const Icon(Icons.wallet, color: Colors.white),
                          label: const Text("Create SentryPay Account", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BankSelectionPage(
                                phone: phone,
                                name: name,
                                email: email,
                                firstName: firstName,
                                lastName: lastName,
                                dob: dob,
                                photo: photo,
                                isAddAccount: true,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add bank account", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          side: const BorderSide(color: Color(0xFFD1FAE5), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
