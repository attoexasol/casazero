import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/app_colors.dart';
import '../utils/accessibility.dart';

class CZNotificationBell extends StatefulWidget {
  final int count;
  final VoidCallback? onTap;

  const CZNotificationBell({super.key, required this.count, this.onTap});

  @override
  State<CZNotificationBell> createState() => _CZNotificationBellState();
}

class _CZNotificationBellState extends State<CZNotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOut,
      ),
    );
  }

  Future<void> _handleTap() async {
    // Play shrink animation
    await _controller.forward();

    // Play bounce back animation
    await _controller.reverse();

    // Call original onTap (no functionality change)
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        borderRadius: BorderRadius.circular(50.r),
        onTap: _handleTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Accessibility.minTouchTarget,
            minHeight: Accessibility.minTouchTarget,
          ),
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.brandSage50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 24.sp,
                    color: AppColors.brandSage600,
                  ),
                ),

                if (widget.count > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: 14.w,
                        minHeight: 14.w,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.white, width: 1.5.w),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.count > 9 ? "9+" : widget.count.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
