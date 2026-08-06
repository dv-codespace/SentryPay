import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/smooth_tap.dart';
import '../payments/upi_pin_page.dart';
import '../onboarding/pin_setup_page.dart';
import '../payments/scan_page.dart';

class AccountDetailsPage extends StatefulWidget {
  final String phone;
  final String userName;
  final Map<String, dynamic> account;

  const AccountDetailsPage({
    super.key,
    required this.phone,
    required this.userName,
    required this.account,
  });

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  late Map<String, dynamic> _account;
  bool _isUpdating = false;

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
    "Federal Bank": "assets/banks/Federal.png"
  };

  @override
  void initState() {
    super.initState();
    _account = Map<String, dynamic>.from(widget.account);
  }

  Future<void> _setAsPrimary() async {
    setState(() => _isUpdating = true);
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.phone);
      final doc = await userDocRef.get();
      final userData = doc.data() ?? {};
      List<dynamic> accounts = List.from(userData['accounts'] ?? []);
      
      for (var acc in accounts) {
        if (acc['bank'] == _account['bank']) {
          acc['isPrimary'] = true;
        } else {
          acc['isPrimary'] = false;
        }
      }

      await userDocRef.update({
        'accounts': accounts,
        'bank': _account['bank'], // update global fallback bank
      });

      setState(() {
        _account['isPrimary'] = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${_account['bank']} set as primary account"),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      Navigator.pop(context, true); // Pop back notifying parent to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating primary account: $e")),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _checkBalance() {
    final upiPin = _account['upiPin'] ?? "";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpiPinPage(
          amount: "0",
          riskScore: 0,
          suspiciousIntent: false,
          isBalanceCheck: true,
          expectedPin: upiPin,
          bankName: _account['bank'],
          accountNo: _account['accountNo'],
        ),
      ),
    ).then((value) {
      if (value == true) {
        final double balance = _account['balance'] != null 
            ? (_account['balance'] is int ? (_account['balance'] as int).toDouble() : _account['balance'] as double) 
            : 0.0;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text("Account Balance"),
            content: Text(
              "Available balance in your ${_account['bank']} account is:\n\n₹${balance.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    });
  }

  void _resetUpiPin() {
    final upiPin = _account['upiPin'] ?? "";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpiPinPage(
          amount: "0",
          riskScore: 0,
          suspiciousIntent: false,
          isBalanceCheck: true,
          expectedPin: upiPin,
          isResetPinFlow: true,
          bankName: _account['bank'],
          accountNo: _account['accountNo'],
        ),
      ),
    ).then((value) {
      if (value == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PinSetupPage(
              phone: widget.phone,
              name: widget.userName,
              email: "",
              bank: _account['bank'],
              firstName: "",
              lastName: "",
              dob: "",
              isReset: true,
            ),
          ),
        ).then((_) {
          // Re-fetch account details to reflect new PIN
          FirebaseFirestore.instance.collection('users').doc(widget.phone).get().then((doc) {
            if (doc.exists) {
              final accounts = doc.data()?['accounts'] ?? [];
              for (var acc in accounts) {
                if (acc['bank'] == _account['bank']) {
                  if (mounted) {
                    setState(() {
                      _account = Map<String, dynamic>.from(acc);
                    });
                  }
                }
              }
            }
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bankName = _account['bank'] ?? "";
    final isPrimary = _account['isPrimary'] ?? false;
    final accountNo = _account['accountNo'] ?? "";
    final upiId = _account['upiId'] ?? "";
    final logoPath = _bankLogos[bankName];

    final isWallet = bankName == "SentryPay Wallet";
    final accountType = isWallet ? "Digital Wallet" : "Savings Account";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Account Details",
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          isWallet
                              ? Image.asset('assets/logo2.png', width: 50, height: 50, fit: BoxFit.contain)
                              : (logoPath != null
                                  ? Image.asset(logoPath, width: 50, height: 50, fit: BoxFit.contain)
                                  : const CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Color(0xFFE8FFF5),
                                      child: Icon(Icons.account_balance, color: Color(0xFF059669), size: 28),
                                    )),
                          const SizedBox(height: 16),
                          Text(
                            bankName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$accountType • $accountNo",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                          if (isPrimary) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8FFF5),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: const Color(0xFFD1FAE5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF059669), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "Primary Account",
                                    style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Detail Information Section
                    const Text(
                      "Account details",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD1FAE5).withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow("Account Holder", widget.userName),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow("Mobile Number", widget.phone),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow("UPI ID", upiId),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Action buttons
                    const Text(
                      "Settings & Actions",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),

                    if (!isPrimary) ...[
                      _buildActionButton(
                        icon: Icons.check_circle_outline,
                        title: "Set as Primary Account",
                        subtitle: "Use this account for default payments",
                        onTap: _setAsPrimary,
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildActionButton(
                      icon: Icons.qr_code,
                      title: "Display QR Code",
                      subtitle: "Show QR code to receive payments",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScanPage(initialTab: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildActionButton(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Check Account Balance",
                      subtitle: "Verify your available funds",
                      onTap: _checkBalance,
                    ),
                    const SizedBox(height: 12),

                    _buildActionButton(
                      icon: Icons.lock_reset,
                      title: "Reset UPI PIN",
                      subtitle: "Change your security PIN",
                      onTap: _resetUpiPin,
                    ),
                    const SizedBox(height: 12),

                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      title: "Manage UPI ID",
                      subtitle: "Edit or add custom UPI IDs",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Manage UPI ID is not implemented yet.")),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildActionButton(
                      icon: Icons.delete_outline,
                      title: "Remove Account",
                      subtitle: "Disconnect this bank account from SentryPay",
                      iconColor: Colors.red,
                      onTap: _showRemoveConfirmation,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  void _showRemoveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Remove Account"),
        content: Text("Are you sure you want to disconnect your ${_account['bank']} account from SentryPay?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _removeAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  Future<void> _removeAccount() async {
    setState(() => _isUpdating = true);
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.phone);
      final doc = await userDocRef.get();
      final userData = doc.data() ?? {};
      List<dynamic> accounts = List.from(userData['accounts'] ?? []);

      if (accounts.length <= 1) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You must keep at least one connected bank account."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      accounts.removeWhere((acc) => acc['bank'] == _account['bank']);

      // If removed account was primary, set the first remaining account as primary
      final wasPrimary = _account['isPrimary'] == true;
      if (wasPrimary && accounts.isNotEmpty) {
        accounts[0]['isPrimary'] = true;
        await userDocRef.update({
          'accounts': accounts,
          'bank': accounts[0]['bank'], // Update legacy fallback bank
        });
      } else {
        await userDocRef.update({
          'accounts': accounts,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${_account['bank']} disconnected successfully!"),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      Navigator.pop(context, true); // Pop back notifying parent to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error disconnecting account: $e")),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF059669),
  }) {
    final bgIconColor = iconColor == Colors.red ? const Color(0xFFFFECEF) : const Color(0xFFE8FFF5);
    return SmoothTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1FAE5).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
