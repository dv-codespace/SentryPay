import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../models/contact_model.dart';
import '../../models/fraud_log.dart';

final List<ContactModel> appContacts = [
  ContactModel(name: "Rahul", riskScore: 3, tag: "Friend", avatarColor: const Color(0xFF8B5CF6)),
  ContactModel(name: "Priya", riskScore: 12, tag: "Merchant", avatarColor: const Color(0xFF3B82F6)),
  ContactModel(name: "Arun", riskScore: 0, tag: "Family", avatarColor: const Color(0xFF10B981)),
  ContactModel(name: "Sneha", riskScore: 8, tag: "Friend", avatarColor: const Color(0xFFF59E0B)),
  ContactModel(name: "Karthik", riskScore: 15, tag: "Business", avatarColor: const Color(0xFFEC4899)),
  ContactModel(name: "Divya", riskScore: 2, tag: "Family", avatarColor: const Color(0xFFEF4444)),
  ContactModel(name: "Vikram", riskScore: 10, tag: "Merchant", avatarColor: const Color(0xFF8B5CF6)),
  ContactModel(name: "Ananya", riskScore: 5, tag: "Friend", avatarColor: const Color(0xFF3B82F6)),
];

ContactModel getContactDetails(String name) {
  return appContacts.firstWhere(
    (c) => c.name.toLowerCase() == name.toLowerCase(),
    orElse: () => ContactModel(
      name: name,
      riskScore: 0,
      tag: "Friend",
      avatarColor: const Color(0xFF059669),
    ),
  );
}

Map<String, dynamic> lastTransactionContext = {
  "risk_score": null,
  "risk_level": null,
  "reasons": null,
  "url": null,
  "intent_result": null,
  "scam_result": null,
  "liveness_active": false,
};

double walletBalance = 15890.74;

List<Map<String, dynamic>> transactionHistory = [
  {
    "title": "To: Priya",
    "name": "Priya",
    "number": "+91 98765 43210",
    "amount": "- ₹1,200.00",
    "status": "SUCCESS",
    "date": "Yesterday, 4:15 PM"
  },
  {
    "title": "Blocked Payment",
    "name": "Suspicious Shop",
    "number": "upi://pay?pa=fake@upi",
    "amount": "- ₹5,000.00",
    "status": "BLOCKED",
    "date": "12 July 2026, 11:30 AM"
  },
  {
    "title": "To: Rahul",
    "name": "Rahul",
    "number": "+91 90123 45678",
    "amount": "- ₹500.00",
    "status": "SUCCESS",
    "date": "10 July 2026, 9:20 PM"
  },
  {
    "title": "Blocked Payment",
    "name": "Lottery Scam Link",
    "number": "https://win-free-prize.xyz",
    "amount": "- ₹15,000.00",
    "status": "BLOCKED",
    "date": "08 July 2026, 2:10 PM"
  },
  {
    "title": "To: Arun",
    "name": "Arun",
    "number": "+91 87654 32109",
    "amount": "- ₹250.00",
    "status": "SUCCESS",
    "date": "05 July 2026, 6:45 PM"
  }
];

List<FraudLog> fraudHistory = [];

late List<CameraDescription> cameras;

