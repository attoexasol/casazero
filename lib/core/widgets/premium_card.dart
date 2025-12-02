import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';

class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showShadow;
  final bool enableHoverEffect;

  const PremiumCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor,
    this.onTap,
    this.showShadow = true,
    this.enableHoverEffect = true,
  }) : super(key: key);

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        margin: widget.margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: widget.enableHoverEffect
                ? (_) => _controller.forward()
                : null,
            onTapUp: widget.enableHoverEffect ? (_) => _controller.reverse() : null,
            onTapCancel:
            widget.enableHoverEffect ? () => _controller.reverse() : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: AppColors.neutralLine100,
                  width: 1,
                ),
                boxShadow: widget.showShadow ? AppShadows.shadowLg : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
