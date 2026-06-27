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

  /// 0 = fully expanded, 1 = fully collapsed (Instagram-style shrink on scroll).
  final double collapseProgress;

  const FloatingBottomNavBar({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.iconBuilder,
    this.collapseProgress = 0,
  });

  static const Duration animationDuration = Duration(milliseconds: 280);
  static const Curve animationCurve = Curves.easeInOut;

  static const double _tabletBreakpoint = 600;
  static const double _tabletMaxBarWidth = 600;

  static double get barHeight => 72.h;

  static double get collapsedBarHeight => 64.h;

  static double get bottomMargin => 16.h;

  static double get collapsedBottomMargin => 12.h;

  /// Bar width when fully collapsed, as a fraction of the expanded width.
  static const double collapsedWidthScale = 0.92;

  static double _lerp(double expanded, double collapsed, double t) {
    return expanded + (collapsed - expanded) * t.clamp(0.0, 1.0);
  }

  /// Gap between scrollable content and the floating nav bar.
  static double get contentGap => 24.h;

  static double _horizontalPadding(double screenWidth) {
    if (screenWidth >= _tabletBreakpoint) return 24.w;
    return 20.w;
  }

  static double _maxBarWidth(double screenWidth) {
    if (screenWidth >= _tabletBreakpoint) return _tabletMaxBarWidth;
    return double.infinity;
  }

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
    final t = collapseProgress.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final baseHorizontalPadding = _horizontalPadding(screenWidth);
    final baseMaxBarWidth = _maxBarWidth(screenWidth);
    final currentHorizontalPadding = _lerp(
      baseHorizontalPadding,
      baseHorizontalPadding + 10.w,
      t,
    );
    final expandedBarWidth = baseMaxBarWidth == double.infinity
        ? screenWidth - (baseHorizontalPadding * 2)
        : baseMaxBarWidth;
    final collapsedBarWidth = expandedBarWidth * collapsedWidthScale;
    final currentBarWidth = _lerp(expandedBarWidth, collapsedBarWidth, t);
    final currentBarHeight = _lerp(barHeight, collapsedBarHeight, t);
    final currentBottomMargin = _lerp(bottomMargin, collapsedBottomMargin, t);
    final borderRadiusValue = _lerp(38.r, 34.r, t);
    final borderRadius = BorderRadius.circular(borderRadiusValue);
    final borderWidth = _lerp(1.5.w, 1.4.w, t);
    final iconScale = _lerp(1.0, 0.94, t);
    final activeIconBoost = _lerp(1.1, 1.06, t);
    final blurSigma = _lerp(8.0, 7.0, t);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        currentHorizontalPadding,
        0,
        currentHorizontalPadding,
        currentBottomMargin + bottomInset,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: currentBarWidth,
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withOpacity(0.85),
                width: borderWidth,
              ),
            ),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandSage500.withOpacity(isDark ? 0.14 : 0.10),
                  blurRadius: _lerp(36.r, 32.r, t),
                  spreadRadius: _lerp(-6.r, -5.r, t),
                  offset: Offset(0, _lerp(14.h, 12.h, t)),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.20 : 0.10),
                  blurRadius: _lerp(28.r, 24.r, t),
                  spreadRadius: _lerp(-4.r, -3.r, t),
                  offset: Offset(0, _lerp(10.h, 8.h, t)),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.10 : 0.04),
                  blurRadius: _lerp(8.r, 7.r, t),
                  offset: Offset(0, _lerp(2.h, 2.h, t)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: Container(
                      height: currentBarHeight,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white.withOpacity(0.18),
                    ),
                  ),
                  SizedBox(
                    height: currentBarHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tabWidth = constraints.maxWidth / itemCount;
                        final showIndicator =
                            selectedIndex >= 0 && selectedIndex < itemCount;
                        // Pill size is proportional to the bar/tab so it shrinks in sync
                        // with the nav during scroll (not fixed .w/.h units).
                        final pillHeight = currentBarHeight * 0.56;
                        final pillWidth = tabWidth * _lerp(0.74, 0.70, t);
                        final pillLeft = showIndicator
                            ? (selectedIndex * tabWidth) +
                                ((tabWidth - pillWidth) / 2)
                            : 0.0;
                        final pillRadius = pillHeight / 2;

                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            if (showIndicator)
                              Positioned(
                                left: pillLeft,
                                top: (constraints.maxHeight - pillHeight) / 2,
                                width: pillWidth,
                                height: pillHeight,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(pillRadius),
                                    color: isDark
                                        ? Colors.white.withOpacity(0.28)
                                        : const Color(0xFFC8C8C8)
                                            .withOpacity(0.95),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                          isDark ? 0.15 : 0.08,
                                        ),
                                        blurRadius: _lerp(6.r, 5.r, t),
                                        offset: Offset(0, _lerp(2.h, 2.h, t)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Row(
                              children: List.generate(itemCount, (index) {
                                final isActive =
                                    selectedIndex >= 0 && selectedIndex == index;
                                return Expanded(
                                  child: _FloatingNavItem(
                                    height: currentBarHeight,
                                    isActive: isActive,
                                    iconScale: isActive ? activeIconBoost : iconScale,
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
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  final double height;
  final bool isActive;
  final double iconScale;
  final VoidCallback onTap;
  final Widget icon;

  const _FloatingNavItem({
    required this.height,
    required this.isActive,
    required this.iconScale,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Center(
          child: Transform.scale(
            scale: iconScale,
            child: icon,
          ),
        ),
      ),
    );
  }
}
