import '../../core/widgets/smooth_tap.dart';
import 'package:flutter/material.dart';
import 'pin_setup_page.dart';

class BankSelectionPage extends StatefulWidget {
  final String phone;
  final String name;
  final String email;
  final String firstName;
  final String lastName;
  final String dob;
  final String? photo;
  final bool isAddAccount;

  const BankSelectionPage({
    super.key,
    required this.phone,
    required this.name,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dob,
    this.photo,
    this.isAddAccount = false,
  });

  @override
  State<BankSelectionPage> createState() => _BankSelectionPageState();
}

class _BankSelectionPageState extends State<BankSelectionPage> {
  final List<String> _banks = [
    "State Bank of India",
    "Indian Overseas Bank",
    "HDFC Bank",
    "ICICI Bank",
    "Axis Bank",
    "Canara Bank",
    "Indian Bank",
    "Punjab National Bank",
    "Kotak Mahindra Bank",
    "Federal Bank"
  ];

  final Map<String, String> _bankLogos = {
    "State Bank of India": "assets/banks/SBI.png",
    "Indian Overseas Bank": "assets/banks/IOB.png",
    "HDFC Bank": "assets/banks/HDFC.png",
    "ICICI Bank": "assets/banks/ICICI.png",
    "Axis Bank": "assets/banks/Axis.png",
    "Canara Bank": "assets/banks/Canara.png",
    "Indian Bank": "assets/banks/Indian Bank.png",
    "Punjab National Bank": "assets/banks/PNB.png",
    "Kotak Mahindra Bank": "assets/banks/Kotak.png",
    "Federal Bank": "assets/banks/Federal.png"
  };

  String _searchQuery = "";
  String? _selectedBank;

  void _onNext() {
    if (_selectedBank == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinSetupPage(
          phone: widget.phone,
          name: widget.name,
          email: widget.email,
          bank: _selectedBank!,
          firstName: widget.firstName,
          lastName: widget.lastName,
          dob: widget.dob,
          photo: widget.photo,
          isAddAccount: widget.isAddAccount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBanks = _banks.where((b) => b.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Select Bank", style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: "Search your bank...",
                    prefixIcon: Icon(Icons.search, color: Color(0xFF059669)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: filteredBanks.length,
                itemBuilder: (context, index) {
                  final bank = filteredBanks[index];
                  final isSelected = _selectedBank == bank;
                  final logoPath = _bankLogos[bank];

                  return SmoothTap(
                    onTap: () => setState(() => _selectedBank = bank),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD1FAE5) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF059669) : const Color(0xFFD1FAE5).withOpacity(0.5),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(color: const Color(0xFF059669).withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))
                        ] : [],
                      ),
                      child: ListTile(
                        leading: logoPath != null
                            ? Image.asset(
                                logoPath,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              )
                            : CircleAvatar(
                                backgroundColor: const Color(0xFFF8FFFC),
                                child: Icon(Icons.account_balance, color: isSelected ? const Color(0xFF059669) : Colors.grey.shade600, size: 20),
                              ),
                        title: Text(
                          bank,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: Color(0xFF059669)) 
                          : const SizedBox.shrink(),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedBank != null ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Link Bank Account",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
