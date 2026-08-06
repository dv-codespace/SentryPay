import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> userExists(String phone) async {
    final doc = await _db.collection("users").doc(phone).get();
    return doc.exists;
  }

  static Future<Map<String, dynamic>?> getUser(String phone) async {
    final doc = await _db.collection("users").doc(phone).get();
    return doc.data();
  }

  static Future<void> saveUser({
    required String phone,
    required String name,
    required String email,
    required String bank,
    required String appPin,
    String? firstName,
    String? lastName,
    String? dob,
    String? photo,
  }) async {
    String getBankAcronym(String bankName) {
      final cleanBank = bankName.trim().toLowerCase();
      if (cleanBank.contains("sentrypay wallet")) return "sentrypay";
      if (cleanBank.contains("state bank of india")) return "sbi";
      if (cleanBank.contains("indian overseas bank")) return "iob";
      if (cleanBank.contains("hdfc bank")) return "hdfc";
      if (cleanBank.contains("icici bank")) return "icici";
      if (cleanBank.contains("axis bank")) return "axis";
      if (cleanBank.contains("canara bank")) return "canara";
      if (cleanBank.contains("indian bank")) return "indian";
      if (cleanBank.contains("punjab national bank")) return "pnb";
      if (cleanBank.contains("kotak mahindra bank")) return "kotak";
      if (cleanBank.contains("federal bank")) return "federal";
      return bankName.split(" ").map((w) => w.isNotEmpty ? w[0].toUpperCase() : "").join();
    }

    final String cleanName = name.replaceAll(" ", "").toLowerCase();
    final String cleanBank = getBankAcronym(bank).toLowerCase();
    final String upiId = bank == "SentryPay Wallet" 
        ? "$phone@sentrypay" 
        : "$cleanName-$cleanBank@sentrypay";

    final defaultAccount = {
      "bank": bank,
      "upiPin": appPin,
      "balance": 5000.0,
      "accountNo": bank == "SentryPay Wallet" ? "Wallet" : "•••• 8742",
      "isPrimary": true,
      "upiId": upiId,
    };

    await _db.collection("users").doc(phone).set({
      "phone": phone,
      "name": name,
      "email": email,
      "bank": bank,
      "appPin": appPin,
      "firstName": firstName,
      "lastName": lastName,
      "dob": dob,
      "photo": photo,
      "accounts": [defaultAccount],
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateRegisteredFace(String phone, String faceImagePath) async {
    await _db.collection("users").doc(phone).update({
      "registeredFace": faceImagePath,
      "faceRegisteredAt": FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveSession(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("phone", phone);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("phone");
  }
}
