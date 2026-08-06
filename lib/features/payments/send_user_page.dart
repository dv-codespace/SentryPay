import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/data/app_data.dart';
import 'payment_page.dart';
import 'analysis_page.dart';

class SendUserPage extends StatefulWidget {
  const SendUserPage({super.key});

  @override
  State<SendUserPage> createState() => _SendUserPageState();
}

class _SendUserPageState extends State<SendUserPage> {
  TextEditingController userController = TextEditingController();
  
  String _selfPhone = "";
  List<dynamic> _recentContacts = [];
  List<Map<String, dynamic>> _allDbUsers = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadData();
    userController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    userController.removeListener(_onSearchChanged);
    userController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString("phone") ?? "";
      setState(() {
        _selfPhone = phone;
      });

      if (phone.isNotEmpty) {
        // Load self profile to get recent contacts
        final selfDoc = await FirebaseFirestore.instance.collection("users").doc(phone).get();
        final selfData = selfDoc.data() ?? {};
        
        // Load all database users for real-time search
        final usersSnap = await FirebaseFirestore.instance.collection("users").get();
        final List<Map<String, dynamic>> allUsers = [];
        for (var doc in usersSnap.docs) {
          if (doc.id != phone) {
            allUsers.add(doc.data() as Map<String, dynamic>);
          }
        }

        setState(() {
          _recentContacts = List.from(selfData['recentContacts'] ?? []);
          _allDbUsers = allUsers;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = userController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final filtered = _allDbUsers.where((user) {
      final name = (user['name'] ?? "").toString().toLowerCase();
      final phone = (user['phone'] ?? "").toString().toLowerCase();
      
      List<dynamic> accounts = List.from(user['accounts'] ?? []);
      bool upiMatch = accounts.any((acc) {
        final upiId = (acc['upiId'] ?? "").toString().toLowerCase();
        return upiId.contains(query);
      });

      return name.contains(query) || phone.contains(query) || upiMatch;
    }).toList();

    setState(() {
      _searchResults = filtered;
    });
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
                      "Send Money",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: userController,
                  decoration: InputDecoration(
                    hintText: "Search contact or enter number",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (userController.text.isNotEmpty && _searchResults.isNotEmpty) ...[
                          const Text(
                            "Suggestions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              final name = user['name'] ?? "Unknown";
                              final phone = user['phone'] ?? "";
                              final last4 = phone.length >= 4 ? phone.substring(phone.length - 4) : phone;
                              
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE8FFF5),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : "U",
                                    style: const TextStyle(
                                      color: Color(0xFF059669),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(name),
                                subtitle: Text("•••• $last4"),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  setState(() {
                                    _selectedUser = user;
                                    userController.text = name;
                                    _searchResults = [];
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        const Text(
                          "Recent Contacts",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _recentContacts.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Text(
                                  "No Recent Contacts",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = _recentContacts[index];
                                  return recentContactWidget(contact);
                                },
                              ),
                        
                        const SizedBox(height: 30),

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
                            onPressed: () {
                              if (userController.text.trim().isEmpty) {
                                return;
                              }

                              if (_selectedUser != null) {
                                final name = _selectedUser!['name'] ?? "";
                                final phone = _selectedUser!['phone'] ?? "";
                                List<dynamic> accounts = List.from(_selectedUser!['accounts'] ?? []);
                                final primaryAccount = accounts.firstWhere(
                                  (acc) => acc['isPrimary'] == true,
                                  orElse: () => accounts.isNotEmpty ? accounts.first : {},
                                );
                                final upiId = primaryAccount['upiId'] ?? "";

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentPage(
                                      qrData: "manual://pay",
                                      riskScore: -1,
                                      receiverName: name,
                                      receiverPhone: phone,
                                      receiverUpiId: upiId,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentPage(
                                      qrData: "manual://pay",
                                      riskScore: -1,
                                      receiverName: userController.text,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "Continue",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    Widget recentContactWidget(Map<String, dynamic> contact) {
      final name = contact['name'] ?? "Unknown";
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8FFF5),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "U",
            style: const TextStyle(
              color: Color(0xFF059669),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          setState(() {
            final matchingUser = _allDbUsers.firstWhere(
              (u) => u['phone'] == contact['phone'],
              orElse: () => {
                "name": contact['name'],
                "phone": contact['phone'],
                "accounts": [
                  {
                    "upiId": contact['upiId'],
                    "isPrimary": true,
                  }
                ]
              },
            );
            _selectedUser = matchingUser;
            userController.text = name;
          });
        },
      );
    }
  }
