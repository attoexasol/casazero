import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 14.h + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            ...AppShadows.shadowLg,
            BoxShadow(
              color: AppColors.brandSage500.withOpacity(isDark ? 0.14 : 0.1),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 72.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          AppColors.neutralInk800.withOpacity(0.96),
                          AppColors.neutralInk900.withOpacity(0.9),
                        ]
                      : [
                          AppColors.surfaceWhite.withOpacity(0.97),
                          AppColors.surfaceWarm50.withOpacity(0.92),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? AppColors.neutralInk700.withOpacity(0.5)
                      : AppColors.surfaceWhite.withOpacity(0.85),
                  width: 1.2,
                ),
              ),
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
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        AppColors.brandSage500
                                            .withOpacity(0.28),
                                        AppColors.brandSage500
                                            .withOpacity(0.14),
                                      ]
                                    : [
                                        AppColors.brandSage50,
                                        AppColors.brandSage100
                                            .withOpacity(0.65),
                                      ],
                              ),
                              boxShadow: AppShadows.customColoredShadow(
                                AppColors.brandSage500,
                                opacity: isDark ? 0.22 : 0.16,
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
              opacity: isActive ? 1.0 : 0.48,
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
