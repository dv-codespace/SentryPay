import 'package:flutter/material.dart';
import '../../core/data/app_data.dart';
import '../../core/widgets/smooth_tap.dart';
import 'send_user_page.dart';

class SendMoneyPage extends StatefulWidget {
  final String name;

  const SendMoneyPage({super.key, required this.name});

  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {

  TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Money"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 30),

            /// Receiver Profile
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green.shade100,
              child: Text(
                widget.name[0],
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            /// Amount Field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Amount",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: () {

                  String amount = amountController.text;

                  if(amount.isNotEmpty){

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "₹$amount sent to ${widget.name}",
                        ),
                      ),
                    );

                    Navigator.pop(context);
                  }
                },

                child: const Text(
                  "Send Money",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}
