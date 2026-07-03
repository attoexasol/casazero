import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import 'platform_safe_area.dart';

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

  /// Horizontal pill slide when switching tabs — tuned per platform.
  static Duration get pillSlideDuration =>
      isIOS ? const Duration(milliseconds: 300) : const Duration(milliseconds: 280);

  static Curve get pillSlideCurve => Curves.easeInOutCubic;

  /// Active pill width as a fraction of each tab slot.
  static double _pillWidthFactor(double collapseProgress) {
    final t = collapseProgress.clamp(0.0, 1.0);
    // iOS bar is narrower — use a slightly wider pill so it stays visually balanced.
    final expanded = isIOS ? 0.76 : 0.74;
    final collapsed = isIOS ? 0.72 : 0.70;
    return _lerp(expanded, collapsed, t);
  }

  /// Active pill height as a fraction of bar height.
  static double get _pillHeightFactor => isIOS ? 0.58 : 0.56;

  static const double _tabletBreakpoint = 600;
  static const double _tabletMaxBarWidth = 600;

  /// Android uses a taller pill; iOS uses a compact bar closer to the home indicator.
  static double get barHeight => isIOS ? 56.h : 72.h;

  static double get collapsedBarHeight => isIOS ? 48.h : 64.h;

  /// iOS already has a large home-indicator inset — keep only a small visual gap.
  static double get bottomMargin => isIOS ? 6.h : 16.h;

  static double get collapsedBottomMargin => isIOS ? 4.h : 12.h;

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

  /// Bottom padding below the bar (home indicator + optional margin).
  static double navBottomPadding(
    BuildContext context, {
    double margin = 0,
  }) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final effectiveMargin = margin > 0 ? margin : bottomMargin;

    if (isIOS && bottomInset > 0) {
      // Instagram-style: sit low in the safe area instead of stacking full inset + margin.
      return effectiveMargin + (bottomInset * 0.38);
    }

    return effectiveMargin + bottomInset;
  }

  /// Total vertical space the floating nav occupies from the screen bottom.
  static double occupiedHeight(BuildContext context) {
    return barHeight + navBottomPadding(context);
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
    final expandedRadius = isIOS ? 32.r : 38.r;
    final collapsedRadius = isIOS ? 28.r : 34.r;
    final borderRadiusValue = _lerp(expandedRadius, collapsedRadius, t);
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
        navBottomPadding(context, margin: currentBottomMargin),
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
                    child: _FloatingNavTrack(
                      itemCount: itemCount,
                      selectedIndex: selectedIndex,
                      collapseProgress: t,
                      currentBarHeight: currentBarHeight,
                      isDark: isDark,
                      iconScale: iconScale,
                      activeIconBoost: activeIconBoost,
                      onItemSelected: onItemSelected,
                      iconBuilder: iconBuilder,
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

/// Tab row + sliding active pill. Animates horizontally on tab change;
/// updates instantly on scroll collapse so the pill stays aligned with the bar.
class _FloatingNavTrack extends StatefulWidget {
  final int itemCount;
  final int selectedIndex;
  final double collapseProgress;
  final double currentBarHeight;
  final bool isDark;
  final double iconScale;
  final double activeIconBoost;
  final ValueChanged<int> onItemSelected;
  final FloatingNavIconBuilder iconBuilder;

  const _FloatingNavTrack({
    required this.itemCount,
    required this.selectedIndex,
    required this.collapseProgress,
    required this.currentBarHeight,
    required this.isDark,
    required this.iconScale,
    required this.activeIconBoost,
    required this.onItemSelected,
    required this.iconBuilder,
  });

  @override
  State<_FloatingNavTrack> createState() => _FloatingNavTrackState();
}

class _FloatingNavTrackState extends State<_FloatingNavTrack>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  Animation<double>? _activeLeftAnimation;

  double _pillLeft = 0;
  int _committedIndex = -1;
  bool _animateTabSwitch = false;
  bool _pillUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: FloatingBottomNavBar.pillSlideDuration,
    )..addListener(_onSlideTick);
  }

  @override
  void dispose() {
    _slideController.removeListener(_onSlideTick);
    _slideController.dispose();
    super.dispose();
  }

  void _onSlideTick() {
    final animation = _activeLeftAnimation;
    if (animation != null && mounted) {
      setState(() => _pillLeft = animation.value);
    }
  }

  @override
  void didUpdateWidget(covariant _FloatingNavTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animateTabSwitch = true;
    } else if (oldWidget.collapseProgress != widget.collapseProgress ||
        oldWidget.currentBarHeight != widget.currentBarHeight) {
      _animateTabSwitch = false;
      _slideController.stop();
      _activeLeftAnimation = null;
    }
  }

  void _snapPillTo(double left) {
    _slideController.stop();
    _activeLeftAnimation = null;
    _pillLeft = left;
  }

  void _slidePillTo(double from, double to) {
    _slideController.stop();
    _activeLeftAnimation = Tween<double>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: FloatingBottomNavBar.pillSlideCurve,
    ));
    _slideController.forward(from: 0);
  }

  void _schedulePillUpdate({
    required double targetLeft,
    required int selectedIndex,
    required bool showIndicator,
  }) {
    if (!showIndicator) return;

    if (_committedIndex < 0) {
      _snapPillTo(targetLeft);
      _committedIndex = selectedIndex;
      return;
    }

    if (selectedIndex == _committedIndex) {
      if (!_slideController.isAnimating) {
        _snapPillTo(targetLeft);
      }
      return;
    }

    if (_pillUpdateScheduled) return;

    final shouldAnimate = _animateTabSwitch;
    _animateTabSwitch = false;
    final from = _pillLeft;
    final to = targetLeft;
    final toIndex = selectedIndex;
    _pillUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pillUpdateScheduled = false;
      if (!mounted) return;
      if (widget.selectedIndex != toIndex) return;

      if (shouldAnimate) {
        _slidePillTo(from, to);
      } else {
        _snapPillTo(to);
      }
      _committedIndex = toIndex;
      setState(() {});
    });
  }

  double _pillLeftForIndex(int index, double tabWidth, double pillWidth) {
    return (index * tabWidth) + ((tabWidth - pillWidth) / 2);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.collapseProgress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / widget.itemCount;
        final showIndicator = widget.selectedIndex >= 0 &&
            widget.selectedIndex < widget.itemCount;
        final pillHeight = widget.currentBarHeight *
            FloatingBottomNavBar._pillHeightFactor;
        final pillWidth =
            tabWidth * FloatingBottomNavBar._pillWidthFactor(t);
        final targetLeft = showIndicator
            ? _pillLeftForIndex(widget.selectedIndex, tabWidth, pillWidth)
            : 0.0;
        final pillRadius = pillHeight / 2;
        final pillTop = (constraints.maxHeight - pillHeight) / 2;

        _schedulePillUpdate(
          targetLeft: targetLeft,
          selectedIndex: widget.selectedIndex,
          showIndicator: showIndicator,
        );

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (showIndicator)
              Positioned(
                left: _pillLeft,
                top: pillTop,
                width: pillWidth,
                height: pillHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(pillRadius),
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.28)
                        : const Color(0xFFC8C8C8).withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          widget.isDark ? 0.15 : 0.08,
                        ),
                        blurRadius: FloatingBottomNavBar._lerp(6.r, 5.r, t),
                        offset: Offset(
                          0,
                          FloatingBottomNavBar._lerp(2.h, 2.h, t),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: List.generate(widget.itemCount, (index) {
                final isActive =
                    widget.selectedIndex >= 0 && widget.selectedIndex == index;
                return Expanded(
                  child: _FloatingNavItem(
                    height: widget.currentBarHeight,
                    isActive: isActive,
                    iconScale:
                        isActive ? widget.activeIconBoost : widget.iconScale,
                    onTap: () => widget.onItemSelected(index),
                    icon: widget.iconBuilder(index, isActive),
                  ),
                );
              }),
            ),
          ],
        );
      },
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
