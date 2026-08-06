import 'package:flutter/material.dart';
import 'bank_account_page.dart';
import 'manage_account_page.dart';

class ManageCardsPage extends StatefulWidget {
  const ManageCardsPage({super.key});

  @override
  State<ManageCardsPage> createState() => _ManageCardsPageState();
}

class _ManageCardsPageState extends State<ManageCardsPage> {
  bool _cardBlocked = false;
  bool _onlineTxEnabled = true;
  bool _internationalTxEnabled = false;
  double _limitValue = 25000.0;
  bool _showCvv = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Manage Cards"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _cardBlocked
                      ? [Colors.grey.shade800, Colors.grey.shade900]
                      : [
                          const Color(0xFF6366F1),
                          const Color(0xFFEC4899),
                          const Color(0xFF3B82F6),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cardBlocked ? Colors.black26 : const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SentryPay Premium",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            "Secure Debit",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _cardBlocked ? Icons.lock : Icons.contactless,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ],
                  ),
                  const Text(
                    "••••  ••••  ••••  5694",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CARDHOLDER",
                            style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5),
                          ),
                          Text(
                            "SentryPay User",
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "EXPIRES",
                            style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5),
                          ),
                          Text(
                            _cardBlocked ? "••/••" : "12/31",
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CVV",
                            style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showCvv = !_showCvv;
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  _showCvv && !_cardBlocked ? "415" : "•••",
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _showCvv ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "CARD CONTROLS",
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            _buildControlTile(
              "Temporary Block Card",
              "Instantly lock card transactions anytime",
              Icons.block,
              _cardBlocked,
              (val) {
                setState(() {
                  _cardBlocked = val;
                });
              },
            ),
            _buildControlTile(
              "Online / E-Commerce Transactions",
              "Allow payment on web apps and websites",
              Icons.shopping_cart,
              _onlineTxEnabled,
              _cardBlocked
                  ? null
                  : (val) {
                      setState(() {
                        _onlineTxEnabled = val;
                      });
                    },
            ),
            _buildControlTile(
              "International Usage",
              "Transactions outside country borders",
              Icons.public,
              _internationalTxEnabled,
              _cardBlocked
                  ? null
                  : (val) {
                      setState(() {
                        _internationalTxEnabled = val;
                      });
                    },
            ),
            const SizedBox(height: 25),
            const Text(
              "TRANSACTION LIMITS",
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daily POS/ATM Limit",
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "₹${_limitValue.toInt()}",
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _limitValue,
                    min: 5000,
                    max: 100000,
                    divisions: 19,
                    activeColor: const Color(0xFF10B981),
                    inactiveColor: Colors.white24,
                    onChanged: _cardBlocked
                        ? null
                        : (val) {
                            setState(() {
                              _limitValue = val;
                            });
                          },
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₹5,000", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      Text("₹1,00,000", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControlTile(String title, String subtitle, IconData icon, bool val, ValueChanged<bool>? onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (onChanged == null ? Colors.grey.shade700 : const Color(0xFF10B981)).withOpacity(0.12),
            child: Icon(icon, color: onChanged == null ? Colors.grey : const Color(0xFF10B981)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: onChanged == null ? Colors.grey : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withOpacity(0.4),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
