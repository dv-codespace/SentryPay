import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'bank_account_page.dart';
import 'manage_cards_page.dart';
import '../auth/login_page.dart';

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({super.key});

  @override
  State<ManageAccountPage> createState() => _ManageAccountPageState();
}

class _ManageAccountPageState extends State<ManageAccountPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String _selfPhone = "";
  String? _photoPath;
  bool _isLoading = true;
  bool _isSaving = false;
  String _upiId = "";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString("phone") ?? "";
      if (phone.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection("users").doc(phone).get();
        final data = userDoc.data() ?? {};
        
        List<dynamic> accounts = List.from(data['accounts'] ?? []);
        Map<String, dynamic> primaryAccount = accounts.firstWhere(
          (acc) => acc['isPrimary'] == true,
          orElse: () => accounts.isNotEmpty ? accounts.first : {},
        );
        final upiId = primaryAccount['upiId'] ?? "$phone@sentrypay";

        setState(() {
          _selfPhone = phone;
          _nameController.text = data['name'] ?? "";
          _emailController.text = data['email'] ?? "";
          _photoPath = data['photo'];
          _upiId = upiId;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (selected != null) {
        setState(() {
          _photoPath = selected.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty"), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection("users").doc(_selfPhone).update({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "photo": _photoPath ?? "",
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            SizedBox(width: 8),
            Text("Remove Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Are you sure you want to permanently remove your SentryPay account? "
          "This will delete your profile details, linked bank accounts, cards, and all transaction histories. This action is irreversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              setState(() => _isLoading = true);

              try {
                final phone = _selfPhone;
                final db = FirebaseFirestore.instance;

                // Perform batch deletion
                final batch = db.batch();

                // 1. Delete user document
                batch.delete(db.collection("users").doc(phone));

                // 2. Delete user's notifications
                final notifSnap = await db.collection("notifications").where("recipientPhone", isEqualTo: phone).get();
                for (var doc in notifSnap.docs) {
                  batch.delete(doc.reference);
                }

                // 3. Delete transactions involving user
                final txSnap1 = await db.collection("transactions").where("senderPhone", isEqualTo: phone).get();
                for (var doc in txSnap1.docs) {
                  batch.delete(doc.reference);
                }
                final txSnap2 = await db.collection("transactions").where("receiverPhone", isEqualTo: phone).get();
                for (var doc in txSnap2.docs) {
                  batch.delete(doc.reference);
                }

                // 4. Delete messages involving user
                final msgSnap1 = await db.collection("messages").where("senderPhone", isEqualTo: phone).get();
                for (var doc in msgSnap1.docs) {
                  batch.delete(doc.reference);
                }
                final msgSnap2 = await db.collection("messages").where("receiverPhone", isEqualTo: phone).get();
                for (var doc in msgSnap2.docs) {
                  batch.delete(doc.reference);
                }

                // 5. Delete requests involving user
                final reqSnap1 = await db.collection("requests").where("senderPhone", isEqualTo: phone).get();
                for (var doc in reqSnap1.docs) {
                  batch.delete(doc.reference);
                }
                final reqSnap2 = await db.collection("requests").where("receiverPhone", isEqualTo: phone).get();
                for (var doc in reqSnap2.docs) {
                  batch.delete(doc.reference);
                }

                await batch.commit();

                // 6. Clear shared preferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to remove account: $e"), backgroundColor: Colors.red),
                  );
                }
              }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FFFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
      );
    }

    final upiId = _upiId;

    ImageProvider avatarImage;
    if (_photoPath != null && _photoPath!.isNotEmpty) {
      avatarImage = (kIsWeb || _photoPath!.startsWith("http")) 
          ? NetworkImage(_photoPath!) 
          : FileImage(File(_photoPath!)) as ImageProvider;
    } else {
      avatarImage = const AssetImage("assets/profile.png");
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                      "Manage Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Profile and account details",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// PROFILE HEADER CARD (Dynamic Image picker)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: const Color(0xFFD1FAE5),
                              child: CircleAvatar(
                                radius: 49,
                                backgroundImage: avatarImage,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 4),
                                    ],
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : "SentryPay User",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          upiId,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// EDITABLE DETAILS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Personal Information",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),

                        const Text("Name", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: "Enter full name",
                            filled: true,
                            fillColor: const Color(0xFFF8FFFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        const Text("Email Address", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: "Enter email address",
                            filled: true,
                            fillColor: const Color(0xFFF8FFFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// MANAGE BANK & CARDS SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Account Configuration",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.account_balance, color: Color(0xFF059669)),
                          title: const Text("Manage Bank Accounts"),
                          subtitle: const Text("Add, remove or set default accounts"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BankAccountPage()),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.credit_card, color: Color(0xFF059669)),
                          title: const Text("Manage Cards"),
                          subtitle: const Text("Configure credit and debit cards"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManageCardsPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// DANGER ZONE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Danger Zone",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 15),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.delete_forever, color: Colors.red),
                          title: const Text("Remove Account"),
                          subtitle: const Text("Permanently delete data and close SentryPay profile"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _deleteAccount,
                        ),
                      ],
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
}
