import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selfPhone = "";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelf();
  }

  Future<void> _loadSelf() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selfPhone = prefs.getString("phone") ?? "";
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF34D399), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                }

                final docs = snapshot.data!.docs;
                final userNotifications = docs
                    .where((doc) => (doc.data() as Map<String, dynamic>)['recipientPhone'] == _selfPhone)
                    .toList();

                // Sort descending by timestamp
                userNotifications.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final bTime = (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return bTime.compareTo(aTime);
                });

                if (userNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "No notifications yet",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  itemCount: userNotifications.length,
                  itemBuilder: (context, index) {
                    final doc = userNotifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? "Notification";
                    final body = data['body'] ?? "";
                    final read = data['read'] ?? false;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeStr = timestamp != null
                        ? "${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                        : "";

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8FFF5),
                          child: Icon(
                            title.toLowerCase().contains("payment") ? Icons.arrow_downward : Icons.notifications,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(body),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (timeStr.isNotEmpty)
                              Text(
                                timeStr,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            if (!read) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ]
                          ],
                        ),
                        onTap: () {
                          if (!read) {
                            FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(doc.id)
                                .update({'read': true});
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
