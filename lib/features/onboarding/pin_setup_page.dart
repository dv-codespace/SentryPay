import '../../core/widgets/smooth_tap.dart';
import 'package:flutter/material.dart';
import 'confirm_pin_page.dart';

class PinSetupPage extends StatefulWidget {
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

  const PinSetupPage({
    super.key,
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
  });

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String _pin = "";
  final int _pinLength = 4;

  void _onKeyPress(String key) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += key);
      if (_pin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConfirmPinPage(
                setupPin: _pin,
                phone: widget.phone,
                name: widget.name,
                email: widget.email,
                bank: widget.bank,
                firstName: widget.firstName,
                lastName: widget.lastName,
                dob: widget.dob,
                photo: widget.photo,
                isReset: widget.isReset,
                isAddAccount: widget.isAddAccount,
              ),
            ),
          );
        });
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
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
              widget.isReset ? "Set New UPI PIN" : "Set UPI PIN",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isReset ? "Enter your new 4-digit security PIN" : "Enter a 4-digit PIN for future payments",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 60),
            Row(
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
                    color: isFilled ? const Color(0xFF059669) : Colors.grey.shade300,
                    boxShadow: isFilled ? [
                      BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
                    ] : [],
                  ),
                );
              }),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["1", "2", "3"].map((key) => _buildKey(key)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["4", "5", "6"].map((key) => _buildKey(key)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["7", "8", "9"].map((key) => _buildKey(key)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 60, height: 60),
                      _buildKey("0"),
                      SmoothTap(
                        onTap: _onBackspace,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF8FFFC)),
                          child: const Icon(Icons.backspace_outlined, color: Color(0xFF059669), size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String key) {
    return SmoothTap(
      onTap: () => _onKeyPress(key),
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF8FFFC)),
        child: Center(
          child: Text(
            key,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }
}
