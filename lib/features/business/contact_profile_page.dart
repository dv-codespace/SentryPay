import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/app_data.dart';

class ContactProfilePage extends StatelessWidget {
  final String contactName;
  final String? contactPhone;
  final String? contactUpiId;

  const ContactProfilePage({
    super.key,
    required this.contactName,
    this.contactPhone,
    this.contactUpiId,
  });

  Future<Map<String, dynamic>?> _fetchContactDetails() async {
    if (contactPhone == null || contactPhone!.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection("users").doc(contactPhone).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchContactDetails(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final phoneToShow = userData?['phone'] ?? contactPhone ?? "+91 XXXXX XXXXX";
        
        List<dynamic> accounts = List.from(userData?['accounts'] ?? []);
        final primaryAccount = accounts.firstWhere(
          (acc) => acc['isPrimary'] == true,
          orElse: () => accounts.isNotEmpty ? accounts.first : {},
        );
        
        final upiIdToShow = primaryAccount['upiId'] ?? contactUpiId ?? "${contactName.toLowerCase()}@sentrypay";
        final bankToShow = primaryAccount['bank'] ?? (userData?['bank']) ?? "SentryPay Wallet";
        
        final int riskScore = userData?['riskScore'] != null
            ? userData!['riskScore'] as int
            : 0;
            
        final String tag = userData?['tag'] ?? "Contact";

        return Scaffold(
          backgroundColor: const Color(0xFFF8FFFC),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                height: 220,
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
                child: Stack(
                  children: [
                    Positioned(
                      top: 50,
                      left: 15,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white24,
                            child: Text(
                              contactName.isNotEmpty ? contactName[0].toUpperCase() : "U",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            contactName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text("Phone Number"),
                subtitle: Text(phoneToShow),
              ),

              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text("UPI ID"),
                subtitle: Text(upiIdToShow),
              ),

              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text("Bank"),
                subtitle: Text(bankToShow),
              ),
              
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text("Category / Relation"),
                subtitle: Text(tag),
              ),
              
              ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: riskScore > 10
                      ? Colors.red
                      : (riskScore > 5 ? Colors.orange : Colors.green),
                ),
                title: const Text("SentryPay Risk Score"),
                subtitle: Text("$riskScore / 15"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (riskScore > 10
                        ? Colors.red
                        : (riskScore > 5 ? Colors.orange : Colors.green))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    riskScore > 10
                        ? "High Risk"
                        : (riskScore > 5 ? "Medium Risk" : "Safe Contact"),
                    style: TextStyle(
                      color: riskScore > 10
                          ? Colors.red
                          : (riskScore > 5 ? Colors.orange : Colors.green),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
