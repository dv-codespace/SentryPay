import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';

class FraudAlertsPage extends StatefulWidget {
  const FraudAlertsPage({super.key});

  @override
  State<FraudAlertsPage> createState() => _FraudAlertsPageState();
}

class _FraudAlertsPageState extends State<FraudAlertsPage> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = "UPI Phishing ID";
  XFile? _screenshotFile;

  @override
  void dispose() {
    _targetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _screenshotFile = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking screenshot: $e");
    }
  }

  void _submitReport() {
    if (_targetController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all the details before reporting."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Fraud Report Submitted"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your scam report has been received successfully! Our security analysts will verify the details immediately."),
            const SizedBox(height: 12),
            Text("Category: $_selectedCategory", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Target: ${_targetController.text}", style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_screenshotFile != null) ...[
              const SizedBox(height: 4),
              Text("Screenshot: ${_screenshotFile!.name}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _targetController.clear();
                _descriptionController.clear();
                _screenshotFile = null;
              });
            },
            child: const Text("OK", style: TextStyle(color: Color(0xFF059669))),
          ),
        ],
      ),
    );
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
                      "Fraud Alerts",
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
                  "Latest scam awareness & community alerts",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ALERTS LIST
                  _buildAlertItem(
                    "Electricity Disconnection SMS Scam",
                    "Fraudsters send messages stating power will be cut tonight unless you call a given number. NEVER call or click such links.",
                    "CRITICAL ALERT",
                    Colors.red,
                  ),
                  _buildAlertItem(
                    "Fake Customer Care Search Fraud",
                    "Scammers upload false support numbers on Google Maps listings of banks. Always call numbers from official web pages.",
                    "HIGH THREAT",
                    Colors.orange,
                  ),
                  _buildAlertItem(
                    "UPI Refund and Reward Links",
                    "An SMS asking you to open a link to claim 'cashback' or 'gas subsidy refund' is fake. Remember, you never need a PIN to RECEIVE money.",
                    "CRITICAL ALERT",
                    Colors.red,
                  ),
                  _buildAlertItem(
                    "Express Courier / Delivery Scam",
                    "Demands are sent to pay customs or warehouse release charges for a package you never ordered. Do not pay.",
                    "ACTIVE THREAT",
                    Colors.amber[800]!,
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    "Report a Suspicious Entity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  /// REPORT FORM CARD
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
                          "Submit Fraud Information",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Report a scammer's UPI ID, phone number, or URL to add to our SentryPay threat database.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        
                        // Category Dropdown
                        const Text("Scam Type", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: [
                            "UPI Phishing ID",
                            "Fraudulent Website / URL",
                            "Impersonation SMS / Call",
                            "Lottery / Reward Link"
                          ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FFFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Target Input
                        const Text("Offending UPI / Phone / URL", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _targetController,
                          decoration: InputDecoration(
                            hintText: "e.g. upi: fraud@okaxis, Phone: +91 98765...",
                            hintStyle: const TextStyle(fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8FFFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description Input
                        const Text("Scam Description", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Briefly explain what happened...",
                            hintStyle: const TextStyle(fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF8FFFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Image attachment picker
                        const Text("Proof Screenshot (Optional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickScreenshot,
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text("Select Image"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF059669),
                                side: const BorderSide(color: Color(0xFF34D399)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _screenshotFile != null
                                    ? _screenshotFile!.name
                                    : "No file selected",
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Report Scam", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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

  Widget _buildAlertItem(String title, String description, String badgeText, Color badgeColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.warning, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }
}
