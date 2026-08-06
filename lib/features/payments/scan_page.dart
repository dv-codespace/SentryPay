import 'package:image_picker/image_picker.dart';
import '../../core/widgets/smooth_tap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firestore_service.dart';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'analysis_page.dart';
import 'qr_intelligence_page.dart';

class ScanPage extends StatefulWidget {
  final int initialTab;
  final bool isAnalysisOnly;
  const ScanPage({super.key, this.initialTab = 0, this.isAnalysisOnly = false});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {

  bool isScanned = false;
  late int selectedTab;
   final MobileScannerController controller =
      MobileScannerController();

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _scanFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bool success = await controller.analyzeImage(image.path);
      if (!success) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text("Scan Failed"),
            content: const Text("No QR Detected in this Image"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Color(0xFF059669))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error scanning from gallery: $e");
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text("Unable to analyze image: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
  @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: Colors.black,

    body: SafeArea(
      child: Column(
        children: [

          /// TOP TAB BAR
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        /// SCAN QR
                        Expanded(
                          child: SmoothTap(
                            onTap: () {
                              setState(() {
                                selectedTab = 0;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: selectedTab == 0
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: selectedTab == 0
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                child: const Text("Scan QR"),
                              ),
                            ),
                          ),
                        ),

                        /// MY QR
                        Expanded(
                          child: SmoothTap(
                            onTap: () {
                              setState(() {
                                selectedTab = 1;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: selectedTab == 1
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: selectedTab == 1
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                child: const Text("My QR"),
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
          ),

          /// CONTENT
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: selectedTab == 0
                  ? KeyedSubtree(key: const ValueKey(0), child: scannerView())
                  : KeyedSubtree(key: const ValueKey(1), child: myQrView()),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget scannerView() {

  return Stack(
    children: [

      /// CAMERA
      MobileScanner(
        controller: controller,

        onDetect: (BarcodeCapture capture) async {

          if (isScanned) return;
          isScanned = true;

          for (final barcode
              in capture.barcodes) {

            final String? code =
                barcode.rawValue;

            if (code != null) {

              await controller.stop();

              await Future.delayed(
                const Duration(
                  milliseconds: 100,
                ),
              );
              
              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AnalysisPage(
                    qrData: code,
                    isAnalysisOnly: widget.isAnalysisOnly,
                  ),
                ),
              );

              break;
            }
          }
        },
      ),

      /// DARK OVERLAY
      Container(
        color: Colors.black.withOpacity(0.55),
      ),

      /// CORNER FRAME
      Center(
        child: Center(
  child: Container(
    width: 260,
    height: 260,

    decoration: BoxDecoration(
      border: Border.all(
        color: const Color(0xFF10B981),
        width: 4,
      ),

      borderRadius:
          BorderRadius.circular(24),

      boxShadow: [
        BoxShadow(
          color: const Color(
            0xFF10B981,
          ).withOpacity(0.4),

          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    ),
  ),
)

      ),

      const Positioned(
        bottom: 180,
        left: 0,
        right: 0,

        child: Text(
          "Align QR within the frame",

          textAlign: TextAlign.center,

          style: TextStyle(
            color: Colors.white70,
          ),
        ),
      ),

      Positioned(
        bottom: 60,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.flash_on, color: Colors.white),
                onPressed: () {
                  controller.toggleTorch();
                },
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
              onPressed: _scanFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text(
                "Choose from Library",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget myQrView() {
  Future<Map<String, dynamic>> fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString("phone");
    if (phone == null) throw Exception("Session not found");
    final data = await FirestoreService.getUser(phone);
    if (data == null) throw Exception("Profile not found");
    return data;
  }

  return FutureBuilder<Map<String, dynamic>>(
    future: fetchProfileData(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Text(
            "Error: ${snapshot.error}",
            style: const TextStyle(color: Colors.white),
          ),
        );
      }

      final userData = snapshot.data ?? {};
      final name = userData['name'] ?? "Unknown User";
      final phone = userData['phone'] ?? "Unknown Phone";
      final upiId = "${phone}@sentrypay";

      return Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/QR Code.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      upiId,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8FFF5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Receive Money Securely",
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget corner(Color color) {

  return Container(
    width: 40,
    height: 40,

    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: color,
          width: 5,
        ),

        left: BorderSide(
          color: color,
          width: 5,
        ),
      ),

      borderRadius:
          BorderRadius.circular(12),
    ),
  );
}
}
