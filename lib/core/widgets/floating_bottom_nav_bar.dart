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

  static const Duration animationDuration = Duration(milliseconds: 280);
  static const Curve animationCurve = Curves.easeInOut;

  static double get barHeight => 72.h;

  static double get bottomMargin => 16.h;

  /// Gap between scrollable content and the floating nav bar.
  static const double contentGap = 24;

  /// Total vertical space the floating nav occupies from the screen bottom.
  static double occupiedHeight(BuildContext context) {
    return barHeight + bottomMargin + MediaQuery.paddingOf(context).bottom;
  }

  /// Bottom inset for screen content when the floating nav is visible.
  static double contentBottomPadding(BuildContext context) {
    return occupiedHeight(context) + contentGap;
  }

  /// Bottom scroll padding so content clears the floating nav with [contentGap].
  /// Use on [SingleChildScrollView] when no extra horizontal/top inset is needed.
  static EdgeInsets scrollBottomPadding(BuildContext context) {
    return EdgeInsets.only(bottom: contentBottomPadding(context));
  }

  /// Standard padding for main tab screens — always the same bottom nav clearance.
  /// Pass [horizontal] / [top] for list screens; scroll screens use bottom only via [top]/[horizontal] = 0.
  static EdgeInsets screenPadding(
    BuildContext context, {
    double horizontal = 0,
    double top = 0,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      contentBottomPadding(context),
    );
  }

  /// [ListView] screens (documents, maintenance): horizontal 16 + nav clearance.
  static EdgeInsets listPadding(
    BuildContext context, {
    double horizontal = 16,
    double top = 0,
  }) {
    return screenPadding(context, horizontal: horizontal, top: top);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final borderRadius = BorderRadius.circular(38.r);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h + bottomInset),
      child: Container(
        // foregroundDecoration paints AFTER the child — border is always visible
        foregroundDecoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.white.withOpacity(0.85),
            width: 1.5,
          ),
        ),
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
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  height: 72.h,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.18),
                ),
              ),
              SizedBox(
                height: 72.h,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabWidth = constraints.maxWidth / itemCount;
                    final pillWidth = 52.w;
                    final pillHeight = 40.h;
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
                        // Sliding gray pill — active indicator
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
                                borderRadius: BorderRadius.circular(20.r),
                                color: isDark
                                    ? Colors.white.withOpacity(0.28)
                                    : const Color(0xFFC8C8C8).withOpacity(0.95),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.15 : 0.08,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Icons row
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
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: 1.0,
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
