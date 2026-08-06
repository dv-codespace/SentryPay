import 'package:flutter/material.dart';
import 'payment_page.dart';

class BankTransferPage extends StatefulWidget {
  const BankTransferPage({super.key});

  @override
  State<BankTransferPage> createState() => _BankTransferPageState();
}

class _BankTransferPageState extends State<BankTransferPage> {

  TextEditingController accController = TextEditingController();
  TextEditingController ifscController = TextEditingController();
  TextEditingController bankController = TextEditingController();

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
                    "Bank Transfer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                "Transfer directly to bank account",
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

                /// ACCOUNT CARD

                Container(
                  padding:
                      const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                            20),

                    boxShadow: const [
                      BoxShadow(
                        color:
                            Colors.black12,
                        blurRadius: 8,
                      ),
                    ],
                  ),

                  child: const Row(
                    children: [

                      CircleAvatar(
                        radius: 25,

                        backgroundColor:
                            Color(
                                0xFFE8FFF5),

                        child: Icon(
                          Icons
                              .account_balance,
                          color: Color(
                              0xFF059669),
                        ),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Text(
                              "Indian Overseas Bank",

                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            Text(
                              "Savings Account ••••8742",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// ACCOUNT NUMBER

                TextField(
                  controller:
                      accController,

                  decoration:
                      InputDecoration(
                    labelText:
                        "Account Number",

                    prefixIcon:
                        const Icon(
                      Icons.credit_card,
                    ),

                    filled: true,
                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// IFSC

                TextField(
                  controller:
                      ifscController,

                  decoration:
                      InputDecoration(
                    labelText:
                        "IFSC Code",

                    prefixIcon:
                        const Icon(
                      Icons.qr_code,
                    ),

                    filled: true,
                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// BANK

                TextField(
                  controller:
                      bankController,

                  decoration:
                      InputDecoration(
                    labelText:
                        "Bank Name",

                    prefixIcon:
                        const Icon(
                      Icons.account_balance,
                    ),

                    filled: true,
                    fillColor:
                        Colors.white,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// INFO CARD

                Container(
                  padding:
                      const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color:
                        const Color(
                            0xFFE8FFF5),

                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Icon(
                        Icons.security,
                        color: Color(
                            0xFF059669),
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          "Transfers are protected by SentryPay risk analysis and secure verification.",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// PROCEED BUTTON

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                              0xFF059669),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                                    18),
                      ),
                    ),

                    onPressed: () {

                      if (accController
                              .text
                              .isEmpty ||
                          ifscController
                              .text
                              .isEmpty ||
                          bankController
                              .text
                              .isEmpty) {
                        return;
                      }

                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              PaymentPage(
                            qrData:
                                "bank://transfer",

                            riskScore: 30,

                            receiverName:
                                bankController
                                    .text,
                          ),
                        ),
                      );
                    },

                    child: const Text(
                      "Proceed Transfer",

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
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
}
