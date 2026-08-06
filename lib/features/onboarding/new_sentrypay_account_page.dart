import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/widgets/smooth_tap.dart';
import 'pin_setup_page.dart';

class NewSentryPayAccountPage extends StatelessWidget {
  final String phone;
  final String firstName;
  final String lastName;
  final String dob;
  final String email;
  final String? photo;
  final bool isAddAccount;

  const NewSentryPayAccountPage({
    super.key,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.email,
    this.photo,
    this.isAddAccount = false,
  });

  @override
  Widget build(BuildContext context) {
    final String fullName = "$firstName $lastName";
    final String sentryPayId = "$phone@sentrypay";

    ImageProvider? profileImage;
    if (photo != null && photo!.isNotEmpty) {
      profileImage = kIsWeb ? NetworkImage(photo!) : FileImage(File(photo!)) as ImageProvider;
    }

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Your SentryPay Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your digital wallet and ID are ready!",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),

              // Profile Image Illustration
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF059669),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFD1FAE5),
                  backgroundImage: profileImage,
                  child: profileImage == null
                      ? const Icon(Icons.person, size: 60, color: Color(0xFF059669))
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // SentryPay ID Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FFF5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.alternate_email,
                      color: Color(0xFF059669),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sentryPayId,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Set UPI Pin Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PinSetupPage(
                          phone: phone,
                          name: fullName,
                          email: email,
                          bank: "SentryPay Wallet",
                          firstName: firstName,
                          lastName: lastName,
                          dob: dob,
                          photo: photo,
                          isAddAccount: isAddAccount,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Set UPI PIN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
