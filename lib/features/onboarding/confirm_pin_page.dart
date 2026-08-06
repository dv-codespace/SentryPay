import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/smooth_tap.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../features/dashboard/dashboard_page.dart';

class ConfirmPinPage extends StatefulWidget {
  final String setupPin;
  final String phone;
  final String name;
  final String email;
  final String bank;
  final String firstName;
  final String lastName;
  final String dob;
  final String? photo;
  final bool isReset;
  final bool isAddAccount;

  const ConfirmPinPage({
    key,
    required this.setupPin,
    required this.phone,
    required this.name,
    required this.email,
    required this.bank,
    required this.firstName,
    required this.lastName,
    required this.dob,
    this.photo,
    this.isReset = false,
    this.isAddAccount = false,
  }) : super(key: key);

  @override
  State<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends State<ConfirmPinPage> with SingleTickerProviderStateMixin {
  String _pin = "";
  final int _pinLength = 4;
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
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

  void _onKeyPress(String key) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += key;
        _isError = false;
      });
      if (_pin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 300), () async {
          if (_pin == widget.setupPin) {
            try {
              if (widget.isReset) {
                // Pin reset flow - we update the active appPin or specific account PIN
                // To support multi-account PIN update, we update appPin and also search inside accounts
                final hashed = hashPin(_pin);
                final userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.phone);
                final doc = await userDocRef.get();
                final userData = doc.data() ?? {};
                List<dynamic> accounts = List.from(userData['accounts'] ?? []);
                
                // If there are accounts, update the PIN of the matching bank account
                bool updatedAccount = false;
                for (var account in accounts) {
                  if (account['bank'] == widget.bank) {
                    account['upiPin'] = hashed;
                    updatedAccount = true;
                  }
                }
                
                if (updatedAccount) {
                  await userDocRef.update({
                    'accounts': accounts,
                    'appPin': hashed, // Also update global appPin as fallback
                  });
                } else {
                  await userDocRef.update({
                    'appPin': hashed,
                  });
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("UPI PIN successfully updated!"),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context); // Pops ConfirmPinPage
                Navigator.pop(context); // Pops PinSetupPage
              } else if (widget.isAddAccount) {
                // Add bank account flow
                final random = Random();
                final double randomBalance = double.parse((random.nextDouble() * 10000.0).toStringAsFixed(2));
                final String cleanName = widget.name.replaceAll(" ", "").toLowerCase();
                final String cleanBankAcronym = getBankAcronym(widget.bank).toLowerCase();
                final String upiId = widget.bank == "SentryPay Wallet" 
                    ? "${widget.phone}@sentrypay" 
                    : "$cleanName-$cleanBankAcronym@sentrypay";
                
                final newAccount = {
                  "bank": widget.bank,
                  "upiPin": hashPin(_pin),
                  "balance": randomBalance,
                  "accountNo": widget.bank == "SentryPay Wallet" ? "Wallet" : "•••• ${1000 + random.nextInt(9000)}",
                  "isPrimary": false, // Secondary by default
                  "upiId": upiId,
                };

                final userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.phone);
                final doc = await userDocRef.get();
                final userData = doc.data() ?? {};
                List<dynamic> accounts = List.from(userData['accounts'] ?? []);
                
                if (accounts.isEmpty) {
                  // Migrate primary account
                  final primaryBank = userData['bank'] ?? "SentryPay Wallet";
                  final primaryPin = userData['appPin'] ?? "";
                  final String primaryCleanBank = getBankAcronym(primaryBank).toLowerCase();
                  final String primaryUpiId = primaryBank == "SentryPay Wallet"
                      ? "${widget.phone}@sentrypay"
                      : "$cleanName-$primaryCleanBank@sentrypay";
                  accounts.add({
                    "bank": primaryBank,
                    "upiPin": primaryPin,
                    "balance": 5000.0,
                    "accountNo": primaryBank == "SentryPay Wallet" ? "Wallet" : "•••• 8742",
                    "isPrimary": true,
                    "upiId": primaryUpiId,
                  });
                }
                
                // Add new account
                accounts.add(newAccount);
                
                await userDocRef.update({
                  'accounts': accounts,
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${widget.bank} connected successfully!"),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
                
                Navigator.pop(context); // Pops ConfirmPinPage
                Navigator.pop(context); // Pops PinSetupPage
                Navigator.pop(context); // Pops BankSelectionPage / NewSentryPayAccountPage
              } else {
                // Normal onboarding flow
                await FirestoreService.saveUser(
                  phone: widget.phone,
                  name: widget.name,
                  email: widget.email,
                  bank: widget.bank,
                  appPin: hashPin(_pin),
                  firstName: widget.firstName,
                  lastName: widget.lastName,
                  dob: widget.dob,
                  photo: widget.photo,
                );
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                  (route) => false,
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Failed to save PIN: $e"),
                ),
              );
            }
          } else {
            setState(() {
              _isError = true;
              _pin = "";
            });
            _shakeController.forward(from: 0);
          }
        });
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              widget.isReset ? "Confirm New UPI PIN" : "Confirm UPI PIN",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isError ? "PINs do not match. Try again." : (widget.isReset ? "Re-enter your new 4-digit PIN" : "Re-enter your 4-digit PIN"),
              style: TextStyle(
                fontSize: 14, 
                color: _isError ? Colors.red : Colors.grey.shade600,
                fontWeight: _isError ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 60),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(sin(_shakeAnimation.value * pi) * 10, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  bool isFilled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError ? Colors.red : (isFilled ? const Color(0xFF059669) : Colors.grey.shade300),
                      boxShadow: isFilled && !_isError ? [
                        BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
                      ] : [],
                    ),
                  );
                }),
              ),
            ),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["1", "2", "3"].map((e) => _buildKey(e)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["4", "5", "6"].map((e) => _buildKey(e)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["7", "8", "9"].map((e) => _buildKey(e)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 70),
              _buildKey("0"),
              GestureDetector(
                onTap: _onBackspace,
                child: Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  child: const Icon(Icons.backspace_outlined, size: 28, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String text) {
    return SmoothTap(
      onTap: () => _onKeyPress(text),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }
}