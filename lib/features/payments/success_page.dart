import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../core/data/app_data.dart';
import '../dashboard/dashboard_page.dart';

class SuccessPage extends StatefulWidget {
  final String amount;
  final double amountValue;
  final String receiverName;
  final String? senderPhone;
  final String? receiverPhone;
  final String? senderBank;
  final String? receiverBank;
  final String? requestId;

  const SuccessPage({
    super.key,
    required this.amount,
    required this.amountValue,
    this.receiverName = "UPI Merchant",
    this.senderPhone,
    this.receiverPhone,
    this.senderBank,
    this.receiverBank,
    this.requestId,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    walletBalance -= widget.amountValue;

    transactionHistory.add({
      "title": "To: ${widget.receiverName}",
      "name": widget.receiverName,
      "number": widget.receiverPhone != null && widget.receiverPhone!.length >= 4
          ? "+91 XXXXX ${widget.receiverPhone!.substring(widget.receiverPhone!.length - 4)}"
          : "+91 XXXXX XXXXX",
      "amount": "- ₹${widget.amount}",
      "status": "SUCCESS",
      "date": "Today, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
    });

    if (widget.senderPhone != null && widget.receiverPhone != null) {
      _processDbTransaction();
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.bounceOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    _animationController.forward();
    _playSuccessSound();
  }

  Future<void> _processDbTransaction() async {
    try {
      final db = FirebaseFirestore.instance;
      final senderDocRef = db.collection('users').doc(widget.senderPhone);
      final receiverDocRef = db.collection('users').doc(widget.receiverPhone);

      await db.runTransaction((transaction) async {
        final senderDoc = await transaction.get(senderDocRef);
        final receiverDoc = await transaction.get(receiverDocRef);

        if (!senderDoc.exists || !receiverDoc.exists) {
          throw Exception("Sender or Receiver not found in database.");
        }

        final senderData = senderDoc.data() ?? {};
        final receiverData = receiverDoc.data() ?? {};

        // 1. Update Sender Balance
        List<dynamic> senderAccounts = List.from(senderData['accounts'] ?? []);
        bool senderUpdated = false;
        for (var acc in senderAccounts) {
          if (acc['bank'] == widget.senderBank) {
            double currentBal = acc['balance'] != null 
                ? (acc['balance'] is int ? (acc['balance'] as int).toDouble() : acc['balance'] as double)
                : 0.0;
            acc['balance'] = currentBal - widget.amountValue;
            senderUpdated = true;
          }
        }

        // 2. Update Receiver Balance
        List<dynamic> receiverAccounts = List.from(receiverData['accounts'] ?? []);
        bool receiverUpdated = false;
        for (var acc in receiverAccounts) {
          if (acc['isPrimary'] == true) {
            double currentBal = acc['balance'] != null
                ? (acc['balance'] is int ? (acc['balance'] as int).toDouble() : acc['balance'] as double)
                : 0.0;
            acc['balance'] = currentBal + widget.amountValue;
            receiverUpdated = true;
          }
        }
        if (!receiverUpdated && receiverAccounts.isNotEmpty) {
          double currentBal = receiverAccounts[0]['balance'] != null
              ? (receiverAccounts[0]['balance'] is int ? (receiverAccounts[0]['balance'] as int).toDouble() : receiverAccounts[0]['balance'] as double)
              : 0.0;
          receiverAccounts[0]['balance'] = currentBal + widget.amountValue;
          receiverUpdated = true;
        }

        if (senderUpdated) {
          transaction.update(senderDocRef, {'accounts': senderAccounts});
        }
        if (receiverUpdated) {
          transaction.update(receiverDocRef, {'accounts': receiverAccounts});
        }

        // 3. Write to Transaction History in DB
        final txId = "SPTX${100000 + Random().nextInt(900000)}";
        final txDocRef = db.collection('transactions').doc(txId);
        
        final senderUpiId = senderAccounts.firstWhere((a) => a['isPrimary'] == true, orElse: () => senderAccounts.isNotEmpty ? senderAccounts.first : {})['upiId'] ?? "";
        final receiverUpiId = receiverAccounts.firstWhere((a) => a['isPrimary'] == true, orElse: () => receiverAccounts.isNotEmpty ? receiverAccounts.first : {})['upiId'] ?? "";

        final txData = {
          "transactionId": txId,
          "senderName": senderData['name'] ?? widget.senderPhone,
          "senderPhone": widget.senderPhone,
          "senderUpiId": senderUpiId,
          "receiverName": receiverData['name'] ?? widget.receiverName,
          "receiverPhone": widget.receiverPhone,
          "receiverUpiId": receiverUpiId,
          "amount": widget.amountValue,
          "status": "SUCCESS",
          "timestamp": FieldValue.serverTimestamp(),
          "date": "Today, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        };
        transaction.set(txDocRef, txData);

        // 4. Update Sender's recentContacts in DB
        List<dynamic> senderRecent = List.from(senderData['recentContacts'] ?? []);
        
        senderRecent.removeWhere((contact) => contact['phone'] == widget.receiverPhone);
        senderRecent.insert(0, {
          "name": receiverData['name'] ?? widget.receiverName,
          "phone": widget.receiverPhone,
          "upiId": receiverUpiId,
          "photo": receiverData['photo'] ?? "",
        });
        transaction.update(senderDocRef, {'recentContacts': senderRecent});

        // 5. Update Receiver's recentContacts in DB (Symmetrical)
        List<dynamic> receiverRecent = List.from(receiverData['recentContacts'] ?? []);
        receiverRecent.removeWhere((contact) => contact['phone'] == widget.senderPhone);
        receiverRecent.insert(0, {
          "name": senderData['name'] ?? widget.senderPhone,
          "phone": widget.senderPhone,
          "upiId": senderUpiId,
          "photo": senderData['photo'] ?? "",
        });
        transaction.update(receiverDocRef, {'recentContacts': receiverRecent});

        // 6. Write Notification to DB for Receiver
        final notificationDocRef = db.collection('notifications').doc();
        transaction.set(notificationDocRef, {
          "recipientPhone": widget.receiverPhone,
          "title": "Payment Received",
          "body": "${senderData['name'] ?? widget.senderPhone} sent you ₹${widget.amountValue}",
          "timestamp": FieldValue.serverTimestamp(),
          "read": false,
        });

        // 7. Mark Request as Completed if applicable
        if (widget.requestId != null && widget.requestId!.isNotEmpty) {
          final requestDocRef = db.collection('requests').doc(widget.requestId);
          transaction.update(requestDocRef, {'status': 'COMPLETED'});
        }
      });
    } catch (e) {
      debugPrint("Transaction failed: $e");
    }
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('Payment Success Sound.mp3'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140 * _pulseAnimation.value,
                        height: 140 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withOpacity(0.05 * (2.0 - _pulseAnimation.value)),
                        ),
                      ),
                      Container(
                        width: 120 * _pulseAnimation.value,
                        height: 120 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withOpacity(0.1 * (2.0 - _pulseAnimation.value)),
                        ),
                      ),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                "Payment Successful",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sent to ${widget.receiverName}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "₹${widget.amount}",
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Done / Back to Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
