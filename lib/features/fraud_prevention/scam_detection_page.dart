import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/data/app_data.dart';

class ScamDetectionPage extends StatefulWidget {
  const ScamDetectionPage({super.key});

  @override
  State<ScamDetectionPage> createState() => _ScamDetectionPageState();
}

class _ScamDetectionPageState extends State<ScamDetectionPage> {

  final TextEditingController senderController =
    TextEditingController();

final TextEditingController messageController =
    TextEditingController();

bool isAnalyzing = false;

String prediction = "";

double classificationConfidence = 0;

int riskScore = 0;

String riskLevel = "";

String senderStatus = "";

String senderId = "";

String bankName = "";

List<String> reasons = [];

Color resultColor = Colors.green;

 

  List<String> attachedFiles = [];

  bool _isListening = false;
 
  @override
  void initState() {
    super.initState();
    // Removed _initSpeech() as microphone permission is not needed for file attachments.
  }



  void _attachAndTranscribeAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isListening = true; // We use this flag to show loading state
      });
      
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://sentrypay-backend.onrender.com/api/audio/transcribe'), // Uses your Render backend
        );
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            result.files.single.path!,
          ),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var data = jsonDecode(responseData);
          if (data['text'] != null && data['text'].toString().isNotEmpty) {
            setState(() {
              messageController.text = data['text'];
            });
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not transcribe audio')),
            );
          }
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${response.statusCode}')),
            );
        }
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading audio: $e')),
         );
      } finally {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void showAttachFileDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Attach Suspicious File/Document",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select a template file below to simulate uploading an email attachment, document, or screenshot.",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFECEF),
                  child: Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: const Text("Amazon_Invoice_9482.pdf"),
                subtitle: const Text("Simulates order confirmation phishing link"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    attachedFiles = ["Amazon_Invoice_9482.pdf"];
                    messageController.text =
                        "Dear Customer,\n\nWe successfully processed your Amazon order payment of \$1,299.99 for Apple MacBook Air. If you did not make this purchase, immediately login to cancel your payment to avoid fraud charges: http://amazon-secure-order.bit.ly/cancel";
                  });
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFFAEB),
                  child: Icon(Icons.article, color: Colors.orange),
                ),
                title: const Text("IRS_Tax_Refund_Notice.txt"),
                subtitle: const Text("Simulates government/KYC impersonation scam"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    attachedFiles = ["IRS_Tax_Refund_Notice.txt"];
                    messageController.text =
                        "IRS Notice: You have a pending tax refund of \$489.50. To claim your refund, click this link immediately to verify your identity and banking credentials: http://verify-irs-tax.xyz/refund";
                  });
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.image, color: Colors.blue),
                ),
                title: const Text("Win_Cash_Lottery.png"),
                subtitle: const Text("Simulates cash reward lottery ticket scam"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    attachedFiles = ["Win_Cash_Lottery.png"];
                    messageController.text =
                        "CONGRATULATIONS!\n\nYou have been selected as the Grand Prize Winner of the \$1,000,000 Cash Reward! To claim your winnings, click here to contact our transfer agent: http://claim-reward.top/fee";
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }


Future<void> analyzeMessage() async {

  String sender = senderController.text.trim();

  String text = messageController.text.trim();

  if (text.isEmpty) return;

  setState(() {

    isAnalyzing = true;

    prediction = "";

    classificationConfidence = 0;

    riskScore = 0;

    riskLevel = "";

    senderStatus = "";

    senderId = "";

    bankName = "";

    reasons = [];

  });

  try {

    final response = await http.post(

      Uri.parse(
        "https://scam-check-api.onrender.com/analyze",
      ),

      headers: {

        "Content-Type": "application/json",

      },

      body: jsonEncode({

        "sender": sender,

        "message": text,

      }),

    ).timeout(

      const Duration(seconds: 60),

    );

    debugPrint(response.body);

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      lastTransactionContext["scam_result"] = data;

      if (!mounted) return;

      setState(() {

        prediction =
            data["prediction"] ?? "";

        classificationConfidence =
            (data["classification_confidence"] ?? 0)
                .toDouble();

        riskScore =
            (data["risk_score"] ?? 0)
                .toInt();

        riskLevel =
            data["risk_level"] ?? "";

        senderStatus =
            data["sender_status"] ?? "";

        senderId =
            data["sender_id"] ?? "";

        bankName =
            data["bank_name"] ?? "";

        reasons =
            List<String>.from(
              data["reasons"] ?? [],
            );

        switch (riskLevel.toUpperCase()) {

          case "SAFE":

            resultColor = Colors.green;

            break;

          case "MODERATE":

            resultColor = Colors.orange;

            break;

          case "HIGH_RISK":

            resultColor = Colors.red;

            break;

          case "NON_BANK":

            resultColor = Colors.blue;

            break;

          default:

            resultColor = Colors.grey;

        }

        isAnalyzing = false;

      });

    } else {

      if (!mounted) return;

      setState(() {

        isAnalyzing = false;

        prediction = "SERVER ERROR";

        reasons = [

          "Backend returned ${response.statusCode}"

        ];

        resultColor = Colors.red;

      });

    }

  } catch (e) {

    debugPrint(e.toString());

    if (!mounted) return;

    setState(() {

      isAnalyzing = false;

      prediction = "ERROR";

      reasons = [

        "Unable to connect to backend."

      ];

      resultColor = Colors.red;

    });

  }

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
            crossAxisAlignment:
                CrossAxisAlignment.start,

            mainAxisAlignment:
                MainAxisAlignment.center,

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
                    "Scam Check",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              const Text(
                "Analyze suspicious messages and scams",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        /// SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// INPUT LABEL
                const Text(
  "Sender ID (Optional)",
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 10),

TextField(
  controller: senderController,
  textCapitalization: TextCapitalization.characters,
  decoration: InputDecoration(
    hintText: "Example: VK-HDFCBK",
    filled: true,
    fillColor: Colors.white,
    prefixIcon: const Icon(
      Icons.badge,
      color: Color(0xFF059669),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  ),
),

const SizedBox(height: 20),

const Text(
  "Message",
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 10),

TextField(
  controller: messageController,
  maxLines: 6,
  decoration: InputDecoration(
    hintText: "Paste or type the SMS message...",
    filled: true,
    fillColor: Colors.white,
    prefixIcon: const Padding(
      padding: EdgeInsets.only(bottom: 90),
      child: Icon(
        Icons.message,
        color: Color(0xFF059669),
      ),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.all(18),
  ),
),

const SizedBox(height: 20),

              const SizedBox(height: 15),

SizedBox(
  width: double.infinity,
  height: 48,
  child: OutlinedButton.icon(
    onPressed: _isListening
        ? null
        : _attachAndTranscribeAudio,

    icon: _isListening
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
        : const Icon(
            Icons.mic,
            size: 18,
          ),

    label: Text(
      _isListening
          ? "Transcribing..."
          : "Attach Voice Message",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF059669),
      side: const BorderSide(
        color: Color(0xFF34D399),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

const SizedBox(height: 20),
               

                /// ANALYZE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed: isAnalyzing ? null : analyzeMessage,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF059669),

                      foregroundColor:
                          Colors.white,

                      elevation: 4,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                    ),

                    child: isAnalyzing
    ? const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
    : const Text(
        "Analyze Message",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
                  ),
                ),

                const SizedBox(height: 25),

                /// RESULT CARD
               /// RESULT CARD
if (prediction.isNotEmpty)
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

        Row(
          children: [

            Icon(
              Icons.verified_user,
              color: resultColor,
              size: 30,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                prediction,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Text(
          "Risk Score : $riskScore / 100",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Risk Level : $riskLevel",
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 8),

        Text(
          "Classification Confidence : ${classificationConfidence.toStringAsFixed(2)}%",
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 8),

        Text(
          "Sender Status : $senderStatus",
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 8),

        Text(
          "Sender ID : ${senderId.isEmpty ? "N/A" : senderId}",
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 8),

        Text(
          "Bank : ${bankName.isEmpty ? "N/A" : bankName}",
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 18),

        const Text(
          "Why this result?",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ...reasons.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• "),
                Expanded(
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Icon(
                Icons.info_outline,
                color: Colors.orange,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  "This analysis is AI-assisted and may occasionally be incorrect. Always verify sensitive financial requests through official banking channels before taking action.",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),

                /// SECURITY TIPS
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(18),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),

                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Security Tips",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        "• Never share OTPs or PINs",
                      ),

                      SizedBox(height: 5),

                      Text(
                        "• Verify unknown senders",
                      ),

                      SizedBox(height: 5),

                      Text(
                        "• Avoid clicking suspicious links",
                      ),

                      SizedBox(height: 5),

                      Text(
                        "• Check URLs before making payments",
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
@override
void dispose() {
  senderController.dispose();
  messageController.dispose();
  super.dispose();
}
}
