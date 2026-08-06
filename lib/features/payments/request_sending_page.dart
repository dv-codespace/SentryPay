import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class RequestSendingPage extends StatefulWidget {
  final String receiverName;
  final String? receiverPhone;
  final String? receiverUpiId;

  const RequestSendingPage({
    super.key,
    required this.receiverName,
    this.receiverPhone,
    this.receiverUpiId,
  });

  @override
  State<RequestSendingPage> createState() => _RequestSendingPageState();
}

class _RequestSendingPageState extends State<RequestSendingPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  
  String _selfPhone = "";
  String _selfName = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelfData();
  }

  Future<void> _loadSelfData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString("phone") ?? "";
      if (phone.isNotEmpty) {
        final selfDoc = await FirebaseFirestore.instance.collection("users").doc(phone).get();
        final selfData = selfDoc.data() ?? {};
        setState(() {
          _selfPhone = phone;
          _selfName = selfData['name'] ?? "SentryPay User";
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest() async {
    final double amount = double.tryParse(amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid amount"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Add request document
      final reqDocRef = FirebaseFirestore.instance.collection('requests').doc();
      final now = DateTime.now();
      final dateStr = "Today, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      
      batch.set(reqDocRef, {
        "senderPhone": _selfPhone,
        "senderName": _selfName,
        "receiverPhone": widget.receiverPhone ?? "",
        "receiverName": widget.receiverName,
        "amount": amount,
        "purpose": purposeController.text.trim().isNotEmpty ? purposeController.text.trim() : "Request Money",
        "status": "PENDING",
        "timestamp": FieldValue.serverTimestamp(),
        "date": dateStr,
      });

      // 2. Add notification document for the receiver B
      if (widget.receiverPhone != null && widget.receiverPhone!.isNotEmpty) {
        final notifDocRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifDocRef, {
          "recipientPhone": widget.receiverPhone,
          "title": "Payment Request",
          "body": "$_selfName requested ₹${amount.toStringAsFixed(2)} for ${purposeController.text.trim().isNotEmpty ? purposeController.text.trim() : 'Request'}",
          "timestamp": FieldValue.serverTimestamp(),
          "read": false,
        });
      }

      await batch.commit();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Request Sent"),
            content: Text("Payment request sent to ${widget.receiverName}"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close RequestSendingPage
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send request: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : Column(
              children: [
                /// HEADER
                Container(
                  width: double.infinity,
                  height: 180,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            "Request Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Requesting from: ${widget.receiverName}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.receiverPhone != null && widget.receiverPhone!.isNotEmpty)
                        Text(
                          "Phone: ${widget.receiverPhone}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
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
                        const Text(
                          "Amount to Request",
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
                        const SizedBox(height: 35),

                        /// PURPOSE OF REQUEST
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Purpose of Request",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: purposeController,
                          decoration: InputDecoration(
                            hintText: "Enter reason for this request",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        /// REQUEST BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: _sendRequest,
                            child: const Text(
                              "Request",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
