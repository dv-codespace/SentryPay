import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/more_page.dart';
import '../payments/upi_pin_page.dart';
import '../payments/send_user_page.dart';
import '../business/chat_page.dart';
import 'notifications_page.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/data/app_data.dart';
import '../../core/widgets/smooth_tap.dart';
import '../payments/scan_page.dart';
import '../payments/send_money_page.dart';
import '../payments/request_page.dart';
import '../payments/bank_transfer_page.dart';
import '../payments/bills_page.dart';
import '../payments/qr_intelligence_page.dart';
import '../fraud_prevention/scam_detection_page.dart';
import '../fraud_prevention/fraud_alerts_page.dart';
import '../fraud_prevention/security_tips_page.dart';
import '../assistant/sentry_chat_page.dart';
import '../business/business_interaction_page.dart';
import '../cards_accounts/manage_cards_page.dart';
import '../history/history_page.dart';
import '../profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  bool showBalance = false;
  int selectedIndex = 0;
  double _primaryBalance = 0.0;
  String _primaryPin = "";
  String _primaryBank = "";
  String _primaryAccountNo = "";
  List<dynamic> _recentContacts = [];

  @override
  void initState() {
    super.initState();
    _loadPrimaryAccount();
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

  Future<void> _loadPrimaryAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString("phone");
      if (phone != null) {
        final data = await FirebaseFirestore.instance.collection("users").doc(phone).get();
        final userData = data.data() ?? {};
        final name = userData['name'] ?? "";
        final bank = userData['bank'] ?? "SentryPay Wallet";
        final appPin = userData['appPin'] ?? "";
        
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
              "upiPin": appPin,
              "balance": 5000.0,
              "accountNo": bank == "SentryPay Wallet" ? "Wallet" : "•••• 8742",
              "isPrimary": true,
              "upiId": primaryUpiId,
            }
          ];
        }

        final primaryAccount = accounts.firstWhere(
          (acc) => acc['isPrimary'] == true,
          orElse: () => accounts.first,
        );

        if (mounted) {
          setState(() {
            _recentContacts = List.from(userData['recentContacts'] ?? []);
            _primaryBalance = primaryAccount['balance'] != null
                ? (primaryAccount['balance'] is int ? (primaryAccount['balance'] as int).toDouble() : primaryAccount['balance'] as double)
                : 0.0;
            _primaryPin = primaryAccount['upiPin'] ?? "";
            _primaryBank = primaryAccount['bank'] ?? "";
            _primaryAccountNo = primaryAccount['accountNo'] ?? "";
          });
        }
      }
    } catch (_) {}
  }

  Future<String?> _fetchProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString("phone");
      if (phone == null) return null;
      final doc = await FirebaseFirestore.instance.collection("users").doc(phone).get();
      return doc.data()?['photo'] as String?;
    } catch (_) {
      return null;
    }
  }

  final List<String> people = [
    "Rahul","Priya","Arun","Sneha","Karthik","Divya","Vikram","Ananya"
  ];
  final List<String> businesses = [
    "Amazon","Flipkart","Swiggy","Zomato","Uber","Ola","Netflix","Spotify"
  ];

final PageController _pageController =
    PageController();

    @override
void dispose() {
  _pageController.dispose();
  super.dispose();
}

  @override
Widget build(BuildContext context) {

  return Scaffold(

    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sentry Chatbot Button
        SmoothTap(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SentryChatPage(),
              ),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF047857),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3310B981),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Scanner Button
        Container(
          width: 63,
          height: 63,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF34D399),
                Color.fromARGB(255, 2, 83, 57),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5510B981),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 35,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanPage(),
                ),
              );
            },
          ),
        ),
      ],
    ),

    bottomNavigationBar: BottomNavigationBar(
      backgroundColor: const Color(0xFF064E3B),

      currentIndex: selectedIndex,

      onTap: (index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      },

      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,

      selectedLabelStyle:
          const TextStyle(
        fontWeight: FontWeight.bold,
      ),

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.currency_rupee),
          label: "Money",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: "More",
        ),
      ],
    ),

    body: PageView(
      controller: _pageController,

      onPageChanged: (index) {
        setState(() {
          selectedIndex = index;
        });
      },

      children: [
        homeContent(),
        const HistoryPage(),
        const MorePage(),
      ],
    ),
  );
}

  Widget homeContent() {
  return SafeArea(
    child: Column(
      children: [

        /// 🔥 FIXED HEADER
        Container(
          height: 100,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color(0xFF059669),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Row(
                children: [
                  
                  const SizedBox(width: 7),
                  const Text(
                    "Sentry₹Pay",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              ),

              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  SmoothTap(
                    onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        ).then((value) {
                          _loadPrimaryAccount();
                        });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD1FAE5),
                          width: 2.5,
                        ),
                      ),
                      child: FutureBuilder<String?>(
                        future: _fetchProfilePhoto(),
                        builder: (context, snapshot) {
                          final photo = snapshot.data;
                          return CircleAvatar(
                            radius: 20,
                            backgroundImage: (photo != null && photo.isNotEmpty)
                                ? (kIsWeb ? NetworkImage(photo) : FileImage(File(photo)) as ImageProvider)
                                : const AssetImage("assets/profile.png"),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        /// 🔽 SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 💳 BALANCE CARD
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                      Colors.white,
                      Color(0xFFF0FDF4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        _primaryBank.isNotEmpty ? "$_primaryBank Balance" : "Wallet Balance",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 10),

                      showBalance
                          ? Text(
                              "₹ ${_primaryBalance.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            )
                          : const Text(
                              "••••••••",
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),

                      const SizedBox(height: 10),

                      SmoothTap(
                        onTap: () {
                          if (!showBalance) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpiPinPage(
                                  amount: "0",
                                  riskScore: 0,
                                  suspiciousIntent: false,
                                  isBalanceCheck: true,
                                  expectedPin: _primaryPin.isEmpty ? null : _primaryPin,
                                  bankName: _primaryBank.isEmpty ? null : _primaryBank,
                                  accountNo: _primaryAccountNo.isEmpty ? null : _primaryAccountNo,
                                ),
                              ),
                            ).then((value) {
                              if (value == true) {
                                setState(() {
                                  showBalance = true;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              showBalance = false;
                            });
                          }
                        },
                        child: Text(
                          showBalance
                              ? "Hide Balance"
                              : "View Balance",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),
            
          
                const Text("Quick Actions",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Row(
                    children: [
                      const Spacer(flex: 1),
                      quickAction(Icons.send, "Send", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const SendUserPage())
                        );
                      }),
                      const Spacer(flex: 2),
                      quickAction(Icons.receipt_long, "Bills", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const BillsPage())
                        );
                      }),
                      const Spacer(flex: 2),
                      quickAction(Icons.request_page, "Request", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const RequestPage())
                        );
                      }),
                      const Spacer(flex: 2),
                      quickAction(Icons.account_balance, "Transfer", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const BankTransferPage())
                        );
                      }),
                      const Spacer(flex: 1)
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// 👥 PEOPLE
                const Text("People",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                _recentContacts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          "No Payments has done yet",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentContacts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final contact = _recentContacts[index];
                          return dynamicPeopleAvatar(contact);
                        },
                      ),

                const SizedBox(height: 40),

                /// 🏢 BUSINESSES
                const Text("Businesses",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: businesses.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    return businessAvatar(businesses[index]);
                  },
                ),

                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        "",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "© SentryPay | A DV Tech",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    ),
  );
} 

 Widget quickAction(
    IconData icon,
    String label,
    VoidCallback onTap,
) {
  return SmoothTap(
    onTap: onTap,
    child: Column(
      children: [

        Container(
          width: 60,
          height: 60,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34D399),
                Color.fromARGB(255, 27, 213, 151),
              ],
            ),

            boxShadow: const [
              BoxShadow(
                color: Color(0x4410B981),
                blurRadius: 20,
                spreadRadius: 3,
                offset: Offset(0, 8),
              ) ,
            ],
          ),

          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
  Widget dynamicPeopleAvatar(Map<String, dynamic> contact) {
    final name = contact['name'] ?? "Unknown";
    final phone = contact['phone'] ?? "";
    final upiId = contact['upiId'] ?? "";
    
    return SmoothTap(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              contactName: name,
              contactPhone: phone,
              contactUpiId: upiId,
            ),
          ),
        ).then((_) => _loadPrimaryAccount());
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF059669),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3310B981),
                  blurRadius: 20,
                  spreadRadius: 3,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "U",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }

  Widget businessAvatar(String name) {
    final lowercase = name.toLowerCase();
    final extensions = {
      'netflix': 'jpg',
      'ola': 'jpg',
      'swiggy': 'jpg',
    };
    final ext = extensions[lowercase] ?? 'png';
    final imagePath = 'assets/business/$lowercase.$ext';

    return SmoothTap(
      onTap: () {
        /// 👇 Navigate to Payment Page directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessInteractionPage(
              businessName: name,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3310B981),
                  blurRadius: 20,
                  spreadRadius: 3,
                  offset: Offset(0, 8),
                ),
              ],
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }
}
