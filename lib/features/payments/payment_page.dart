import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/data/app_data.dart';
import 'upi_pin_page.dart';
import '../../core/widgets/smooth_tap.dart';

class PaymentPage extends StatefulWidget {  
  final String qrData;
  final int riskScore;
  final String receiverName;
  final bool isPreLivenessVerified;
  final String prefilledAmount;
  final String? receiverPhone;
  final String? receiverUpiId;
  final String? requestId;

  const PaymentPage({
    super.key,
    required this.qrData,
    required this.riskScore,
    this.receiverName = "Divakar",
    this.isPreLivenessVerified = false,
    this.prefilledAmount = "",
    this.receiverPhone,
    this.receiverUpiId,
    this.requestId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {

  TextEditingController amountController = TextEditingController();
  TextEditingController intentController = TextEditingController();

  String _senderPhone = "";
  double _selectedBalance = 0.0;
  String _selectedBank = "";
  String _selectedPin = "";
  String _selectedAccountNo = "";
  List<dynamic> _allAccounts = [];
  bool _showSelectedBalance = false;
  bool _isLoading = true;

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
    if (widget.prefilledAmount.isNotEmpty) {
      amountController.text = widget.prefilledAmount;
    }
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
      final phone = prefs.getString("phone") ?? "";
      if (phone.isNotEmpty) {
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
            _senderPhone = phone;
            _allAccounts = accounts;
            
            _selectedBank = primaryAccount['bank'] ?? "";
            _selectedPin = primaryAccount['upiPin'] ?? "";
            _selectedAccountNo = primaryAccount['accountNo'] ?? "";
            _selectedBalance = primaryAccount['balance'] != null
                ? (primaryAccount['balance'] is int ? (primaryAccount['balance'] as int).toDouble() : primaryAccount['balance'] as double)
                : 0.0;
            _showSelectedBalance = false;
            
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showSwitchAccountSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Choose Bank Account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _allAccounts.length,
                itemBuilder: (context, index) {
                  final acc = _allAccounts[index];
                  final name = acc['bank'] ?? "";
                  final accNo = acc['accountNo'] ?? "";
                  final logoPath = _bankLogos[name];
                  
                  return ListTile(
                    leading: logoPath != null
                        ? Image.asset(logoPath, width: 24, height: 24, fit: BoxFit.contain)
                        : const Icon(Icons.account_balance, color: Color(0xFF059669)),
                    title: Text(name),
                    subtitle: Text(accNo),
                    trailing: _selectedBank == name ? const Icon(Icons.check_circle, color: Color(0xFF059669)) : null,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedBank = name;
                        _selectedPin = acc['upiPin'] ?? "";
                        _selectedAccountNo = accNo;
                        _selectedBalance = acc['balance'] != null
                            ? (acc['balance'] is int ? (acc['balance'] as int).toDouble() : acc['balance'] as double)
                            : 0.0;
                        _showSelectedBalance = false;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _checkSelectedBalance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpiPinPage(
          amount: "0",
          riskScore: 0,
          suspiciousIntent: false,
          isBalanceCheck: true,
          expectedPin: _selectedPin,
          bankName: _selectedBank,
          accountNo: _selectedAccountNo,
        ),
      ),
    ).then((verified) {
      if (verified == true) {
        setState(() {
          _showSelectedBalance = true;
        });
      }
    });
  }

  final List<String> intents = [
    "Paying a friend",
    "Shopping",
    "Food order",
    "Bill payment",
    "Subscription",
    "Other"
  ];

  /// 🔍 Intent Detection
  bool isSuspiciousIntent(String intent) {
    final keywords = [
      "urgent",
      "lottery",
      "gift",
      "free",
      "reward",
      "verify",
      "refund",
      "claim"
    ];

    for (var word in keywords) {
      if (intent.toLowerCase().contains(word)) {
        return true;
      }
    }
    return false;
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

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            mainAxisAlignment:
                MainAxisAlignment.center,

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
                    "Pay Securely",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                "Receiver: ${widget.receiverName}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.riskScore == -1 ? "Risk Score: Not determined yet" : "Risk Score: ${widget.riskScore}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        /// CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                const SizedBox(height: 20),

                /// AMOUNT

                const Text(
                  "Amount",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                Row(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [

    const Text(
      "₹",
      style: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(width: 6),

    SizedBox(
      width: 180,

      child: TextField(
        controller: amountController,
        keyboardType: TextInputType.number,

        textAlign: TextAlign.center,

        style: const TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.bold,
        ),

        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "0",
        ),
      ),
    ),
  ],
),

                const SizedBox(height: 5),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _bankLogos[_selectedBank] != null
                                  ? Image.asset(_bankLogos[_selectedBank]!, width: 20, height: 20, fit: BoxFit.contain)
                                  : const Icon(Icons.account_balance, color: Color(0xFF059669), size: 20),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedBank.isNotEmpty ? _selectedBank : "Loading Bank...",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    _selectedAccountNo.isNotEmpty ? _selectedAccountNo : "",
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _showSwitchAccountSheet,
                            child: const Text("Switch", style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Account Balance", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          _showSelectedBalance
                              ? Text(
                                  "₹ ${_selectedBalance.toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                )
                              : SmoothTap(
                                  onTap: _checkSelectedBalance,
                                  child: const Text(
                                    "Check Balance",
                                    style: TextStyle(
                                      color: Color(0xFF059669),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                /// INTENT TITLE

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Purpose of Payment",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// INTENT BOX

                TextField(
                  controller: intentController,

                  decoration: InputDecoration(
                    hintText:
                        "Why are you making this payment?",

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),

                    contentPadding:
                        const EdgeInsets.all(18),
                  ),
                ),

                const SizedBox(height: 20),

                /// QUICK INTENTS

                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,

                    children:
                        intents.map((intent) {

                      return ChoiceChip(
                        label: Text(intent),

                        selected:
                            intentController.text ==
                                intent,

                        selectedColor:
                            const Color(
                                0xFFE8FFF5),

                        onSelected: (_) {
                          setState(() {
                            intentController.text =
                                intent;
                          });
                        },
                      );

                    }).toList(),
                  ),
                ),

                const SizedBox(height: 40),

                /// PAY BUTTON

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF059669),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                18),
                      ),
                    ),

                    onPressed: () {
                      if (amountController.text.isEmpty) {
                        return;
                      }

                      final enteredAmount = double.tryParse(amountController.text) ?? 0.0;
                      if (enteredAmount > _selectedBalance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Insufficient Balance"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      bool suspicious = isSuspiciousIntent(
                        intentController.text,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpiPinPage(
                            amount: amountController.text,
                            riskScore: widget.riskScore,
                            suspiciousIntent: suspicious,
                            isPreLivenessVerified: widget.isPreLivenessVerified,
                            receiverName: widget.receiverName,
                            receiverPhone: widget.receiverPhone,
                            senderPhone: _senderPhone,
                            senderBank: _selectedBank,
                            expectedPin: _selectedPin,
                            bankName: _selectedBank,
                            accountNo: _selectedAccountNo,
                            requestId: widget.requestId,
                          ),
                        ),
                      );
                    },

                    child: const Text(
                      "Pay Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
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
}
