import '../payments/upi_pin_page.dart';
import '../cards_accounts/manage_cards_page.dart';
import '../../services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import '../../core/data/app_data.dart';
import '../../core/widgets/smooth_tap.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Map<String, bool> _shownBalances = {};
  String _selfPhone = "";
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

  @override
  void initState() {
    super.initState();
    _loadSelfPhone();
  }

  Future<void> _loadSelfPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selfPhone = prefs.getString("phone") ?? "";
    });
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

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return "";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final String timeStr = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    if (txDate == today) {
      return "Today, $timeStr";
    } else if (txDate == yesterday) {
      return "Yesterday, $timeStr";
    } else {
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, $timeStr";
    }
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString("phone");
    if (phone == null) throw Exception("Session not found");
    final data = await FirestoreService.getUser(phone);
    if (data == null) throw Exception("Profile not found");
    return data;
  }

  void _checkBalance(Map<String, dynamic> account) {
    final upiPin = account['upiPin'] ?? "";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpiPinPage(
          amount: "0",
          riskScore: 0,
          suspiciousIntent: false,
          isBalanceCheck: true,
          expectedPin: upiPin,
          bankName: account['bank'],
          accountNo: account['accountNo'],
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          _shownBalances[account['bank']] = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
            );
          }

          final userData = snapshot.data ?? {};
          final name = userData['name'] ?? "Unknown User";
          final phone = userData['phone'] ?? "";
          final bank = userData['bank'] ?? "SentryPay Wallet";
          final appPin = userData['appPin'] ?? "";

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
                "upiPin": appPin,
                "balance": 5000.0,
                "accountNo": bank == "SentryPay Wallet" ? "Wallet" : "•••• 8742",
                "isPrimary": true,
                "upiId": primaryUpiId,
              }
            ];
          }

          return SafeArea(
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF34D399),
                        Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Money",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Manage accounts, cards and transactions",
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Renders all user linked bank accounts
                        ...accounts.map((acc) {
                          final account = Map<String, dynamic>.from(acc);
                          final bankName = account['bank'] ?? "";
                          final accountNo = account['accountNo'] ?? "";
                          final balance = account['balance'] != null
                              ? (account['balance'] is int ? (account['balance'] as int).toDouble() : account['balance'] as double)
                              : 0.0;
                          final logoPath = _bankLogos[bankName];
                          final showBal = _shownBalances[bankName] ?? false;

                          return moneyCard(
                            logoPath: logoPath,
                            title: bankName,
                            subtitle: showBal ? "Balance: ₹${balance.toStringAsFixed(2)}" : accountNo,
                            trailing: showBal ? "Checked" : "Check Balance",
                            onTap: showBal ? null : () => _checkBalance(account),
                          );
                        }).toList(),

                        // Credit cards display (remain unchanged)
                        moneyCard(
                          icon: Icons.credit_card,
                          title: "Cards",
                          subtitle: "2 Active Cards",
                          trailing: "Manage",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ManageCardsPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Recent Transactions",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _selfPhone.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final allTx = snapshot.data!.docs
                                      .map((doc) => doc.data() as Map<String, dynamic>)
                                      .toList();

                                  final userTx = allTx.where((tx) {
                                    return tx['senderPhone'] == _selfPhone || tx['receiverPhone'] == _selfPhone;
                                  }).toList();

                                  userTx.sort((a, b) {
                                    final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                                    final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                                    return bTime.compareTo(aTime);
                                  });

                                  if (userTx.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(40),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.receipt_long,
                                            size: 70,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            "No History Now",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            "Your payments will appear here",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: userTx.length,
                                    itemBuilder: (context, index) {
                                      final tx = userTx[index];
                                      final bool isMeSender = tx['senderPhone'] == _selfPhone;
                                      
                                      final formattedTx = {
                                        "title": isMeSender 
                                            ? "To: ${tx['receiverName'] ?? 'UPI User'}"
                                            : "From: ${tx['senderName'] ?? 'UPI User'}",
                                        "name": isMeSender 
                                            ? (tx['receiverName'] ?? "")
                                            : (tx['senderName'] ?? ""),
                                        "number": isMeSender 
                                            ? (tx['receiverPhone'] ?? "")
                                            : (tx['senderPhone'] ?? ""),
                                        "amount": isMeSender 
                                            ? "- ₹${tx['amount']}"
                                            : "+ ₹${tx['amount']}",
                                        "status": tx['status'] ?? "SUCCESS",
                                        "date": formatDateTime((tx['timestamp'] as Timestamp?)?.toDate()),
                                      };
                                      return transactionTile(formattedTx);
                                    },
                                  );
                                },
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget moneyCard({
  IconData? icon,
  String? logoPath,
  required String title,
  required String subtitle,
  required String trailing,
  VoidCallback? onTap,
}) {
  return SmoothTap(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          logoPath != null
              ? Image.asset(logoPath, width: 40, height: 40, fit: BoxFit.contain)
              : CircleAvatar(
                  backgroundColor: const Color(0xFFE8FFF5),
                  child: Icon(
                    icon ?? Icons.account_balance,
                    color: const Color(0xFF059669),
                  ),
                ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF059669),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget transactionTile(Map<String, dynamic> tx) {
  String title = tx["title"] ?? "Payment";
  String amount = tx["amount"] ?? "₹0.00";
  String status = tx["status"] ?? "SUCCESS";
  String name = tx["name"] ?? "";
  String number = tx["number"] ?? "";
  String date = tx["date"] ?? "";

  IconData icon;
  Color color;

  switch (status) {
    case "SUCCESS":
      icon = Icons.check_circle;
      color = Colors.green;
      break;
    case "BLOCKED":
      icon = Icons.cancel;
      color = Colors.red;
      break;
    default:
      icon = Icons.warning;
      color = Colors.orange;
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          radius: 22,
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 3),
              if (name.isNotEmpty || number.isNotEmpty)
                Text(
                  "${name.isNotEmpty ? name : ''} ${number.isNotEmpty ? '($number)' : ''}".trim(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: status == "BLOCKED"
                ? Colors.grey
                : (amount.startsWith("+") ? Colors.green.shade700 : Colors.red.shade700),
          ),
        ),
      ],
    ),
  );
}
