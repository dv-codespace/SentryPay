import 'package:flutter/material.dart';

class SmoothTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDownTo;
  final Duration duration;

  const SmoothTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDownTo = 0.96,
    this.duration = const Duration(milliseconds: 80),
  });

  @override
  State<SmoothTap> createState() => _SmoothTapState();
}

class _SmoothTapState extends State<SmoothTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDownTo,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
