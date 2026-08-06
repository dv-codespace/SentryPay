import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../features/auth/login_page.dart';
import '../../features/dashboard/dashboard_page.dart';

class SessionChecker extends StatefulWidget {
  final bool isLoggedIn;
  final String? phone;

  const SessionChecker({
    super.key,
    required this.isLoggedIn,
    required this.phone,
  });

  @override
  State<SessionChecker> createState() => _SessionCheckerState();
}

class _SessionCheckerState extends State<SessionChecker> {

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {

    if (!widget.isLoggedIn || widget.phone == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
          (route) => false,
        );
      });
      return;
    }

    final exists =
        await FirestoreService.userExists(widget.phone!);

    if (!mounted) return;

    if (exists) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        ),
        (route) => false,
      );

    } else {

      await FirestoreService.clearSession();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
