import 'package:flutter/material.dart';

class BounceGlowWidget extends StatefulWidget {
  final Widget child;
  final bool active;
  final Duration duration;

  const BounceGlowWidget({
    super.key,
    required this.child,
    required this.active,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<BounceGlowWidget> createState() => _BounceGlowWidgetState();
}

class _BounceGlowWidgetState extends State<BounceGlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Bounce scale effect (grows then shrinks)
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant BounceGlowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) {
        return Transform.scale(
          scale: _scale.value, // bounce in place
          child: child,
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
