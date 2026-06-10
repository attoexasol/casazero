import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';

typedef FloatingNavIconBuilder = Widget Function(int index, bool isActive);

class FloatingBottomNavBar extends StatelessWidget {
  final int itemCount;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final FloatingNavIconBuilder iconBuilder;

  const FloatingBottomNavBar({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.iconBuilder,
  });

  static const Duration animationDuration = Duration(milliseconds: 320);
  static const Curve animationCurve = Curves.easeOutCubic;

  static double get barHeight => 72.h;

  static double get bottomMargin => 16.h;

  /// Total vertical space the floating nav occupies from the screen bottom.
  static double occupiedHeight(BuildContext context) {
    return barHeight + bottomMargin + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final borderRadius = BorderRadius.circular(28.r);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.brandSage500.withOpacity(isDark ? 0.14 : 0.10),
              blurRadius: 36,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.10),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                child: Container(
                  height: 72.h,
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              Container(
                height: 72.h,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.5, 1.0],
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.10),
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ]
                        : [
                            Colors.white.withOpacity(0.22),
                            Colors.white.withOpacity(0.10),
                            AppColors.brandSage50.withOpacity(0.06),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.20)
                        : Colors.white.withOpacity(0.55),
                    width: 1.2,
                  ),
                ),
              ),
              Container(
                height: 72.h,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: const Alignment(0, 0.55),
                    colors: [
                      Colors.white.withOpacity(isDark ? 0.12 : 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 72.h,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / itemCount;
                    final pillWidth = 56.w;
                    final pillHeight = 42.h;
                    final showIndicator =
                        selectedIndex >= 0 && selectedIndex < itemCount;
                    final pillLeft = showIndicator
                        ? (selectedIndex * tabWidth) +
                            ((tabWidth - pillWidth) / 2)
                        : 0.0;

                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedPositioned(
                          duration: animationDuration,
                          curve: animationCurve,
                          left: pillLeft,
                          top: (constraints.maxHeight - pillHeight) / 2,
                          width: pillWidth,
                          height: pillHeight,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: showIndicator ? 1 : 0,
                            curve: Curves.easeInOut,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(21.r),
                                color: isDark
                                    ? AppColors.neutralInk500.withOpacity(0.45)
                                    : AppColors.neutralLine200
                                        .withOpacity(0.72),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.55),
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(itemCount, (index) {
                            final isActive =
                                selectedIndex >= 0 && selectedIndex == index;
                            return Expanded(
                              child: _FloatingNavItem(
                                isActive: isActive,
                                onTap: () => onItemSelected(index),
                                icon: iconBuilder(index, isActive),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final Widget icon;

  const _FloatingNavItem({
    required this.isActive,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 72.h,
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: FloatingBottomNavBar.animationDuration,
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.68,
              duration: FloatingBottomNavBar.animationDuration,
              curve: Curves.easeInOut,
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
