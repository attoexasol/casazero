import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AnimatedGradientContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const AnimatedGradientContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  State<AnimatedGradientContainer> createState() =>
      _AnimatedGradientContainerState();
}

class _AnimatedGradientContainerState extends State<AnimatedGradientContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                AppColors.brandSage500,
                AppColors.accentLime500,
                AppColors.brandSage500,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}