import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firestore_service.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/onboarding/details_collection_page.dart';

class OtpVerifyPage extends StatefulWidget {
  final String phoneNumber;
  const OtpVerifyPage({super.key, required this.phoneNumber});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorText;
  static const String baseUrl =
    "https://sentrypay-backend.onrender.com";

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
  if (_enteredOtp.length != 6) {
    setState(() {
      _errorText = "Enter the complete 6-digit OTP";
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorText = null;
  });

  try {
    final response = await http.post(
      Uri.parse("$baseUrl/api/verify-otp"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phone": "+91${widget.phoneNumber}",
        "otp": _enteredOtp,
      }),
    );

    final data = jsonDecode(response.body);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200 &&
        data["verified"] == true) {

    SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setBool('isLoggedIn', true);
await prefs.setString(
  'phone',
  widget.phoneNumber,
);

final exists =
    await FirestoreService.userExists(widget.phoneNumber);

if (exists) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const DashboardPage(),
    ),
    (route) => false,
  );
} else {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => DetailsCollectionPage(
        phone: widget.phoneNumber,
      ),
    ),
    (route) => false,
  );
}
  
    } else {

      setState(() {
        _errorText = "Invalid OTP";
      });

      for (final c in _controllers) {
        c.clear();
      }

      _focusNodes[0].requestFocus();
    }

  } catch (e) {

    setState(() {
      _isLoading = false;
      _errorText = "Server Error";
    });

  }
}

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD1FAE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() => _errorText = null);
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
         
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF34D399),
                      Color(0xFF059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.sms_outlined, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 24),
              const Text(
                "Verify OTP",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the 6-digit code sent to +91 ${widget.phoneNumber}",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _otpBox(index)),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          "Verify & Continue",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () async {

  try {

    final response = await http.post(
      Uri.parse("$baseUrl/api/send-otp"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phone": "+91${widget.phoneNumber}",
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["success"] == true) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("OTP Sent Again"),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to resend OTP"),
        ),
      );

    }

  } catch (_) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Network Error"),
      ),
    );

  }

},
                  child: const Text(
                    "Resend OTP",
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
