import 'package:flutter/material.dart';
import '../core/utils/smooth_page_transition.dart';
import '../features/auth/session_checker.dart';

class SentryPayApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? phone;

  const SentryPayApp({
    super.key,
    required this.isLoggedIn,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SentryPay',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF8FFFC),
        splashFactory: InkRipple.splashFactory,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (var platform in TargetPlatform.values)
              platform: const SmoothPageTransitionsBuilder(),
          },
        ),
      ),
      home: SessionChecker(
        isLoggedIn: isLoggedIn,
        phone: phone,
      ),
    );
  }
}
