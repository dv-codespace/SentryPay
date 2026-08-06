import '../../services/firestore_service.dart';
import 'liveness_page.dart';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/data/app_data.dart';
import 'success_page.dart';

class UpiPinPage extends StatefulWidget {
  final String amount;
  final int riskScore;
  final bool suspiciousIntent;
  final bool isBalanceCheck;
  final bool isPreLivenessVerified;
  final String receiverName;
  final String? expectedPin;
  final bool isResetPinFlow;
  final String? bankName;
  final String? accountNo;
  final String? senderPhone;
  final String? receiverPhone;
  final String? senderBank;
  final String? receiverBank;
  final String? requestId;

  const UpiPinPage({
    super.key,
    required this.amount,
    required this.riskScore,
    required this.suspiciousIntent,
    this.isBalanceCheck = false,
    this.isPreLivenessVerified = false,
    this.receiverName = "UPI Merchant",
    this.expectedPin,
    this.isResetPinFlow = false,
    this.bankName,
    this.accountNo,
    this.senderPhone,
    this.receiverPhone,
    this.senderBank,
    this.receiverBank,
    this.requestId,
  });

  @override
  State<UpiPinPage> createState() => _UpiPinPageState();
}

class _UpiPinPageState extends State<UpiPinPage> {
  String pin = "";
  bool _isError = false;
  String _bankName = "";
  String _accountNo = "";
  @override
  void initState() {
    super.initState();
    _bankName = widget.bankName ?? "";
    _accountNo = widget.accountNo ?? "";
    if (_bankName.isEmpty || _accountNo.isEmpty) {
      _loadBankDetails();
    }
  }

  Future<void> _loadBankDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString("phone");
      if (phone != null) {
        final data = await FirestoreService.getUser(phone);
        if (data != null) {
          final accounts = data['accounts'] ?? [];
          if (accounts.isNotEmpty) {
            final primary = accounts.firstWhere((a) => a['isPrimary'] == true, orElse: () => accounts.first);
            setState(() {
              _bankName = widget.bankName ?? primary['bank'] ?? "";
              _accountNo = widget.accountNo ?? primary['accountNo'] ?? "";
            });
            return;
          }
          setState(() {
            _bankName = widget.bankName ?? data['bank'] ?? "SentryPay Wallet";
            _accountNo = widget.accountNo ?? (_bankName == "SentryPay Wallet" ? "Wallet" : "•••• 8742");
          });
        }
      }
    } catch (_) {}
  }

  String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  void addDigit(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
        _isError = false;
      });

      if (pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), () async {
          final prefs = await SharedPreferences.getInstance();
          final phone = prefs.getString("phone");
          if (phone == null) return;
          final data = await FirestoreService.getUser(phone);
          if (data == null) return;
          
          if (!mounted) return;

          final storedPin = widget.expectedPin ?? data['appPin'];
          
          if (hashPin(pin) != storedPin) {
            setState(() {
              _isError = true;
              pin = "";
            });
            return;
          }

          /// 🔐 BALANCE CHECK FLOW
          if (widget.isBalanceCheck) {
            Navigator.pop(context, true); // 👈 return success
            return;
          }

          /// 🔐 NORMAL FLOW
          if ((widget.riskScore > 40 || widget.suspiciousIntent) && !widget.isPreLivenessVerified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LivenessPage(
                      amount: widget.amount,
                      receiverName: widget.receiverName,
                      senderPhone: widget.senderPhone,
                      receiverPhone: widget.receiverPhone,
                      senderBank: widget.senderBank,
                      receiverBank: widget.receiverBank,
                    ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SuccessPage(
                      amount: widget.amount,
                      amountValue: double.parse(widget.amount),
                      receiverName: widget.receiverName,
                      senderPhone: widget.senderPhone,
                      receiverPhone: widget.receiverPhone,
                      senderBank: widget.senderBank,
                      receiverBank: widget.receiverBank,
                      requestId: widget.requestId,
                    ),
                ),
            );
          }
        });
      }
    }
  }

  void removeDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.blue,
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// AMOUNT
            if (!widget.isBalanceCheck)
              Column(
                children: [
                  Text(
                    "₹${widget.amount}",
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Paying to",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Scanned Merchant",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

            if (widget.isBalanceCheck)
              Text(
                widget.isResetPinFlow ? "Enter Current UPI PIN" : "Check Account Balance",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 25),

            /// BANK CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bankName.isEmpty ? "Indian Overseas Bank" : _bankName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _accountNo.isEmpty ? "XXXXXX8742" : _accountNo,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            Text(
              widget.isResetPinFlow ? "Enter 4-digit current UPI PIN" : "Enter UPI PIN",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            /// PIN DOTS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: index < pin.length
                        ? Colors.black
                        : Colors.transparent,
                    border: Border.all(
                      color: Colors.black54,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "UPI PIN is issued by your bank",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            if (_isError)
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  "Incorrect UPI PIN",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const Spacer(),

            /// KEYPAD
            Container(
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  keypadRow(["1", "2", "3"]),
                  keypadRow(["4", "5", "6"]),
                  keypadRow(["7", "8", "9"]),
                  Row(
                    children: [
                      Expanded(
                        child: IconButton(
                          icon: const Icon(
                            Icons.backspace_outlined,
                            size: 28,
                          ),
                          onPressed: removeDigit,
                        ),
                      ),
                      Expanded(
                        child: keyButton("0"),
                      ),
                      const Expanded(
                        child: SizedBox(),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget keypadRow(List<String> numbers) {
    return Row(
      children: numbers
          .map(
            (number) => Expanded(
              child: keyButton(number),
            ),
          )
          .toList(),
    );
  }

  Widget keyButton(String number) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => addDigit(number),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            height: 70,
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
