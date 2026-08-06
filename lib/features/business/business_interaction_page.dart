import '../payments/analysis_page.dart';

import 'package:flutter/material.dart';
import '../../core/data/app_data.dart';
import 'chat_page.dart';
import 'contact_profile_page.dart';

class BusinessInteractionPage extends StatefulWidget {
  final String businessName;

  const BusinessInteractionPage({super.key, required this.businessName});

  @override
  State<BusinessInteractionPage> createState() => _BusinessInteractionPageState();
}

class _BusinessInteractionPageState extends State<BusinessInteractionPage> {
  int _selectedPlanIndex = 0;
  final List<Map<String, dynamic>> _netflixPlans = [
    {"name": "Mobile Plan", "price": "149", "desc": "1 Screen, 480p resolution"},
    {"name": "Basic Plan", "price": "199", "desc": "1 Screen, 720p resolution"},
    {"name": "Standard Plan", "price": "499", "desc": "2 Screens, 1080p resolution"},
    {"name": "Premium Plan", "price": "649", "desc": "4 Screens, 4K+HDR resolution"},
  ];
  final List<Map<String, dynamic>> _spotifyPlans = [
    {"name": "Individual Mini", "price": "25", "desc": "1 Account, 1 Week premium"},
    {"name": "Individual Monthly", "price": "119", "desc": "1 Account, 1 Month premium"},
    {"name": "Duo Monthly", "price": "149", "desc": "2 Accounts, 1 Month premium"},
    {"name": "Family Monthly", "price": "179", "desc": "6 Accounts, 1 Month premium"},
  ];
  final List<Map<String, dynamic>> _amazonPlans = [
    {"name": "Prime Shopping Edition", "price": "399", "desc": "1 Year free shopping & delivery"},
    {"name": "Prime Lite Annual", "price": "799", "desc": "1 Year prime video (720p) & delivery"},
    {"name": "Prime Monthly", "price": "299", "desc": "Full Prime features for 1 Month"},
    {"name": "Prime Annual", "price": "1499", "desc": "Full Prime features for 1 Year"},
  ];

  final TextEditingController _pickupController = TextEditingController(text: "Your Current Location");
  final TextEditingController _dropController = TextEditingController();
  int _selectedRideIndex = 0;
  final List<Map<String, dynamic>> _rides = [
    {"type": "Moto Bike", "price": "55", "time": "2 mins away", "icon": Icons.motorcycle},
    {"type": "Auto Rickshaw", "price": "110", "time": "4 mins away", "icon": Icons.electric_rickshaw},
    {"type": "Go Mini Hatch", "price": "175", "time": "3 mins away", "icon": Icons.directions_car},
    {"type": "Prime Sedan Lux", "price": "240", "time": "5 mins away", "icon": Icons.local_taxi},
  ];

  final Map<int, int> _cartQuantities = {};
  final List<Map<String, dynamic>> _foodItems = [
    {"id": 1, "name": "Classic Veg Burger", "price": 129, "desc": "Crispy veg patty with cheese and mayo"},
    {"id": 2, "name": "Cheese Pepperoni Pizza", "price": 349, "desc": "Mozzarella cheese, pepperoni slices, fresh crust"},
    {"id": 3, "name": "Chocolate Brownie Shake", "price": 149, "desc": "Rich milk chocolate blended with brownie chunks"},
    {"id": 4, "name": "Paneer Butter Masala Combo", "price": 249, "desc": "Paneer masala with 2 Butter Naan and Salad"},
  ];
  final List<Map<String, dynamic>> _ecommerceItems = [
    {"id": 1, "name": "Noise ColorFit Smartwatch", "price": 1899, "desc": "1.8-inch display, health tracking, BT calling"},
    {"id": 2, "name": "OnePlus Nord Buds 2", "price": 2499, "desc": "Active Noise Cancellation, 36hr battery, BT Calling"},
    {"id": 3, "name": "Mi Power Bank 3i 20000mAh", "price": 2199, "desc": "18W Fast Charging, Triple Port Output, Sandstone finish"},
    {"id": 4, "name": "SentryPay Smart Hardware Shield", "price": 4999, "desc": "Secure physical OTP token for SentryPay transactions"},
  ];

  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _customInvoiceController = TextEditingController();

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _customAmountController.dispose();
    _customInvoiceController.dispose();
    super.dispose();
  }

  String _getLogoPath(String name) {
    final lowercase = name.toLowerCase();
    final extensions = {
      'netflix': 'jpg',
      'ola': 'jpg',
      'swiggy': 'jpg',
      'zomato': 'jpg',
      'amazon': 'png',
      'flipkart': 'png',
      'spotify': 'png',
      'uber': 'png',
    };
    final ext = extensions[lowercase] ?? 'png';
    return 'assets/business/$lowercase.$ext';
  }

  void _initiatePayment(String amount) {
    if (double.tryParse(amount) == null || double.parse(amount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter or select a valid amount."), backgroundColor: Colors.red),
      );
      return;
    }

    final String qrUri = "upi://pay?pa=${widget.businessName.toLowerCase()}@sentrypay&pn=${widget.businessName}&am=$amount";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisPage(
          qrData: qrUri,
          isAnalysisOnly: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowercase = widget.businessName.toLowerCase();
    final bool isSubscription = ["netflix", "spotify", "amazon"].contains(lowercase);
    final bool isRide = ["uber", "ola"].contains(lowercase);
    final bool isOrder = ["swiggy", "zomato", "flipkart"].contains(lowercase);

    Widget pageBody;

    if (isSubscription) {
      final plans = lowercase == "netflix" 
          ? _netflixPlans 
          : (lowercase == "spotify" ? _spotifyPlans : _amazonPlans);
      
      pageBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select a Subscription Plan",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final p = plans[index];
                final isSelected = _selectedPlanIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlanIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p["name"],
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p["desc"],
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₹${p["price"]}",
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF10B981) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                _initiatePayment(plans[_selectedPlanIndex]["price"]);
              },
              child: Text(
                "Subscribe & Pay (₹${plans[_selectedPlanIndex]["price"]})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else if (isRide) {
      pageBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Book a Ride",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pickupController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Pickup Address",
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.my_location, color: Color(0xFF10B981)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dropController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Destination Address",
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.location_on, color: Colors.red),
              hintText: "Enter destination",
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Available Rides",
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _rides.length,
              itemBuilder: (context, index) {
                final r = _rides[index];
                final isSelected = _selectedRideIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRideIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(r["icon"], color: isSelected ? const Color(0xFF10B981) : Colors.white70, size: 30),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r["type"],
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r["time"],
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₹${r["price"]}",
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF10B981) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (_dropController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please specify your destination drop location."), backgroundColor: Colors.red),
                  );
                  return;
                }
                _initiatePayment(_rides[_selectedRideIndex]["price"]);
              },
              child: Text(
                "Book & Pay (₹${_rides[_selectedRideIndex]["price"]})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else if (isOrder) {
      final items = lowercase == "flipkart" ? _ecommerceItems : _foodItems;
      double total = 0;
      _cartQuantities.forEach((index, qty) {
        if (qty > 0) {
          total += items[index]["price"] * qty;
        }
      });

      pageBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Items to Order",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final it = items[index];
                final qty = _cartQuantities[index] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it["name"],
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              it["desc"],
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "₹${it["price"]}",
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: qty > 0 
                                ? () {
                                    setState(() {
                                      _cartQuantities[index] = qty - 1;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                          ),
                          Text(
                            "$qty",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _cartQuantities[index] = qty + 1;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total:",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "₹${total.toInt()}",
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: total > 0 
                  ? () {
                      _initiatePayment(total.toInt().toString());
                    }
                  : null,
              child: Text(
                "Place Order & Pay (₹${total.toInt()})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else {
      pageBody = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pay Invoice / Bill",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Enter Amount (₹)",
                labelStyle: const TextStyle(color: Colors.white70),
                prefixText: "₹ ",
                prefixStyle: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customInvoiceController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Invoice / Bill Notes",
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: "Enter details (e.g. consultation fee, payment ref)",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  _initiatePayment(_customAmountController.text.trim());
                },
                child: const Text(
                  "Proceed with Payment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasAsset = ["netflix", "spotify", "amazon", "uber", "ola", "swiggy", "zomato", "flipkart"].contains(lowercase);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(widget.businessName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: getContactDetails(widget.businessName).avatarColor,
                    backgroundImage: hasAsset ? AssetImage(_getLogoPath(widget.businessName)) : null,
                    child: !hasAsset 
                        ? Text(
                            widget.businessName[0], 
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.businessName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Verified Business",
                                style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Score: ${getContactDetails(widget.businessName).riskScore}/15",
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: pageBody),
          ],
        ),
      ),
    );
  }
}
