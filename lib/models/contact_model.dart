import 'package:flutter/material.dart';

class ContactModel {
  final String name;
  final int riskScore;
  final String tag;
  final Color avatarColor;

  ContactModel({
    required this.name,
    required this.riskScore,
    required this.tag,
    required this.avatarColor,
  });
}
