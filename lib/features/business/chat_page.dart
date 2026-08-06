import 'contact_profile_page.dart';
import '../payments/payment_page.dart';
import '../payments/request_page.dart';
import '../payments/request_sending_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../core/data/app_data.dart';

class ChatPage extends StatefulWidget {
  final String contactName;
  final String? contactPhone;
  final String? contactUpiId;

  const ChatPage({
    super.key,
    required this.contactName,
    this.contactPhone,
    this.contactUpiId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  String _selfPhone = "";
  bool _loadingSelf = true;

  @override
  void initState() {
    super.initState();
    _loadSelf();
  }

  Future<void> _loadSelf() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selfPhone = prefs.getString("phone") ?? "";
      _loadingSelf = false;
    });
  }

  Stream<List<Map<String, dynamic>>> _combinedChatStream() {
    final StreamController<List<Map<String, dynamic>>> controller = StreamController();
    
    List<Map<String, dynamic>> txList = [];
    List<Map<String, dynamic>> msgList = [];
    List<Map<String, dynamic>> reqList = [];
    
    void update() {
      final combined = [...txList, ...msgList, ...reqList];
      combined.sort((a, b) {
        final aTime = a['timestamp'] as DateTime? ?? DateTime.now();
        final bTime = b['timestamp'] as DateTime? ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      if (!controller.isClosed) {
        controller.add(combined);
      }
    }

    final txSub = FirebaseFirestore.instance.collection('transactions').snapshots().listen((snap) {
      txList = snap.docs.map((doc) {
        final data = doc.data();
        final sPhone = data['senderPhone'] ?? "";
        final rPhone = data['receiverPhone'] ?? "";
        final Timestamp? ts = data['timestamp'] as Timestamp?;
        return {
          "type": "transaction",
          "senderPhone": sPhone,
          "receiverPhone": rPhone,
          "amount": data['amount'],
          "transactionId": data['transactionId'],
          "date": data['date'],
          "timestamp": ts?.toDate(),
        };
      }).where((tx) {
        final sPhone = tx['senderPhone'] ?? "";
        final rPhone = tx['receiverPhone'] ?? "";
        return (sPhone == _selfPhone && rPhone == widget.contactPhone) ||
               (sPhone == widget.contactPhone && rPhone == _selfPhone);
      }).toList();
      update();
    });

    final msgSub = FirebaseFirestore.instance.collection('messages').snapshots().listen((snap) {
      msgList = snap.docs.map((doc) {
        final data = doc.data();
        final sPhone = data['senderPhone'] ?? "";
        final rPhone = data['receiverPhone'] ?? "";
        final Timestamp? ts = data['timestamp'] as Timestamp?;
        return {
          "type": "message",
          "senderPhone": sPhone,
          "receiverPhone": rPhone,
          "text": data['text'],
          "timestamp": ts?.toDate(),
        };
      }).where((msg) {
        final sPhone = msg['senderPhone'] ?? "";
        final rPhone = msg['receiverPhone'] ?? "";
        return (sPhone == _selfPhone && rPhone == widget.contactPhone) ||
               (sPhone == widget.contactPhone && rPhone == _selfPhone);
      }).toList();
      update();
    });

    final reqSub = FirebaseFirestore.instance.collection('requests').snapshots().listen((snap) {
      reqList = snap.docs.map((doc) {
        final data = doc.data();
        final sPhone = data['senderPhone'] ?? "";
        final rPhone = data['receiverPhone'] ?? "";
        final Timestamp? ts = data['timestamp'] as Timestamp?;
        return {
          "type": "request",
          "requestId": doc.id,
          "senderPhone": sPhone,
          "receiverPhone": rPhone,
          "senderName": data['senderName'] ?? "",
          "receiverName": data['receiverName'] ?? "",
          "amount": data['amount'],
          "purpose": data['purpose'] ?? "",
          "status": data['status'] ?? "PENDING",
          "date": data['date'] ?? "",
          "timestamp": ts?.toDate(),
        };
      }).where((req) {
        final sPhone = req['senderPhone'] ?? "";
        final rPhone = req['receiverPhone'] ?? "";
        return (sPhone == _selfPhone && rPhone == widget.contactPhone) ||
               (sPhone == widget.contactPhone && rPhone == _selfPhone);
      }).toList();
      update();
    });

    controller.onCancel = () {
      txSub.cancel();
      msgSub.cancel();
      reqSub.cancel();
    };

    return controller.stream;
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
            height: 130,
            padding: const EdgeInsets.only(
              top: 50,
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
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContactProfilePage(
                            contactName: widget.contactName,
                            contactPhone: widget.contactPhone,
                            contactUpiId: widget.contactUpiId,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Text(
                            widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : "U",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.contactName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// TIMELINE / MESSAGES, PAYMENTS & REQUESTS
          Expanded(
            child: _loadingSelf
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _combinedChatStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final chatItems = snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        reverse: true,
                        itemCount: chatItems.length,
                        itemBuilder: (context, index) {
                          final item = chatItems[index];
                          final isMeSender = item['senderPhone'] == _selfPhone;
                          if (item['type'] == 'transaction') {
                            return transactionBubble(item);
                          } else if (item['type'] == 'request') {
                            return requestBubble(item);
                          } else {
                            return messageBubble(item['text'] ?? "", isMeSender);
                          }
                        },
                      );
                    },
                  ),
          ),

          /// INPUT AREA
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type message",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                /// SEND BUTTON
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      final text = messageController.text.trim();
                      if (text.isEmpty) {
                        return;
                      }
                      messageController.clear();
                      
                      await FirebaseFirestore.instance.collection('messages').add({
                        "senderPhone": _selfPhone,
                        "receiverPhone": widget.contactPhone,
                        "text": text,
                        "timestamp": FieldValue.serverTimestamp(),
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),

                /// PAY BUTTON
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.payments,
                  ),
                  label: const Text(
                    "Pay",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(
                          qrData: "manual://pay",
                          riskScore: -1,
                          receiverName: widget.contactName,
                          receiverPhone: widget.contactPhone,
                          receiverUpiId: widget.contactUpiId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                /// REQUEST BUTTON
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.call_received,
                  ),
                  label: const Text(
                    "Request",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestSendingPage(
                          receiverName: widget.contactName,
                          receiverPhone: widget.contactPhone,
                          receiverUpiId: widget.contactUpiId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return "";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final String timeStr = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    if (txDate == today) {
      return "Today, $timeStr";
    } else if (txDate == yesterday) {
      return "Yesterday, $timeStr";
    } else {
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, $timeStr";
    }
  }

  Widget messageBubble(
    String text,
    bool mine,
  ) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 5,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: mine ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget transactionBubble(Map<String, dynamic> tx) {
    final double amount = tx['amount'] != null
        ? (tx['amount'] is int ? (tx['amount'] as int).toDouble() : tx['amount'] as double)
        : 0.0;
    final String txId = tx['transactionId'] ?? "";
    final String date = formatDateTime(tx['timestamp'] as DateTime?);
    final bool isMeSender = tx['senderPhone'] == _selfPhone;

    return Align(
      alignment: isMeSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMeSender ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isMeSender ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isMeSender ? Icons.arrow_outward : Icons.arrow_downward,
                  color: isMeSender ? const Color(0xFF059669) : Colors.blue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isMeSender ? "Sent Money" : "Received Money",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMeSender ? const Color(0xFF065F46) : const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "₹ ${amount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text("TXID: $txId", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            Text(date, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget requestBubble(Map<String, dynamic> req) {
    final double amount = req['amount'] != null
        ? (req['amount'] is int ? (req['amount'] as int).toDouble() : req['amount'] as double)
        : 0.0;
    final String reqId = req['requestId'] ?? "";
    final String date = formatDateTime(req['timestamp'] as DateTime?);
    final String purpose = req['purpose'] ?? "";
    final String status = req['status'] ?? "PENDING";
    final bool isMeRequester = req['senderPhone'] == _selfPhone;

    return Align(
      alignment: isMeRequester ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMeRequester ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isMeRequester ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.call_received,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isMeRequester ? "Requested Money" : "Request Received",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "₹ ${amount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            if (purpose.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "Reason: $purpose",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 12),
            if (status == "PENDING") ...[
              if (isMeRequester)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Pending Approval",
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            qrData: "manual://pay",
                            riskScore: -1,
                            receiverName: req['senderName'],
                            receiverPhone: req['senderPhone'],
                            prefilledAmount: amount.toString(),
                            requestId: reqId,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Pay",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
            ] else if (status == "COMPLETED") ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Request Completed",
                  style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(date, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
