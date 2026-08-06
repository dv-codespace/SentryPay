import 'package:flutter/material.dart';

class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final primarySlide = Tween<Offset>(
      begin: const Offset(0.08, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );

    final primaryFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
    );

    final secondarySlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.04, 0.0),
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
      ),
    );

    return SlideTransition(
      position: primarySlide,
      child: FadeTransition(
        opacity: primaryFade,
        child: SlideTransition(
          position: secondarySlide,
          child: child,
        ),
      ),
    );
  }
}
