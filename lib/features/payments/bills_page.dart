import 'package:flutter/material.dart';
import '../../core/widgets/smooth_tap.dart';

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFC),

      body: Column(
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            height: 170,

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
                      "Bills & Recharge",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                const Text(
                  "Manage and pay your bills",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),

                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,

                    children: [

                      billCategory(
                        Icons.phone_android,
                        "Mobile",
                      ),

                      billCategory(
                        Icons.tv,
                        "DTH",
                      ),

                      billCategory(
                        Icons.flash_on,
                        "Electricity",
                      ),

                      billCategory(
                        Icons.water_drop,
                        "Water",
                      ),

                      billCategory(
                        Icons.wifi,
                        "Internet",
                      ),

                      billCategory(
                        Icons.local_gas_station,
                        "Gas",
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Upcoming Bills",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  billCard(
                    "Electricity Bill",
                    "Due in 4 days",
                    "₹1,250",
                  ),

                  billCard(
                    "Broadband",
                    "Due in 8 days",
                    "₹899",
                  ),

                  billCard(
                    "Mobile Recharge",
                    "Expires tomorrow",
                    "₹299",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget billCategory(
    IconData icon,
    String title,
  ) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(
            icon,
            size: 30,
            color: const Color(
              0xFF059669,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget billCard(
    String title,
    String due,
    String amount,
  ) {

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),

      child: Row(
        children: [

          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color:
                  const Color(0xFFE8FFF5),

              borderRadius:
                  BorderRadius.circular(
                      14),
            ),

            child: const Icon(
              Icons.receipt_long,
              color:
                  Color(0xFF059669),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                Text(
                  due,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
