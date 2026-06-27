// core/widgets/platform_safe_area.dart
// SafeArea wrapper that respects system insets on all platforms.

import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// Applies [SafeArea] on every platform so content clears notches, Dynamic
/// Island, status bars, and home indicators.
///
/// Usage:
/// ```dart
/// PlatformSafeArea(
///   child: YourWidget(),
/// )
/// ```
class PlatformSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;

  const PlatformSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = false,
    this.right = false,
    this.minimum = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum,
      child: child,
    );
  }
}

/// SafeArea limited to the top inset (notch, Dynamic Island, status bar).
///
/// Usage:
/// ```dart
/// PlatformSafeAreaTop(
///   child: YourWidget(),
/// )
/// ```
class PlatformSafeAreaTop extends StatelessWidget {
  final Widget child;
  final EdgeInsets minimum;

  const PlatformSafeAreaTop({
    super.key,
    required this.child,
    this.minimum = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      left: false,
      right: false,
      minimum: minimum,
      child: child,
    );
  }
}

/// SafeArea limited to the bottom inset (home indicator, gesture bar).
///
/// Usage:
/// ```dart
/// PlatformSafeAreaBottom(
///   child: YourWidget(),
/// )
/// ```
class PlatformSafeAreaBottom extends StatelessWidget {
  final Widget child;
  final EdgeInsets minimum;

  const PlatformSafeAreaBottom({
    super.key,
    required this.child,
    this.minimum = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      left: false,
      right: false,
      minimum: minimum,
      child: child,
    );
  }
}

/// System safe-area padding for the current platform (notch, Dynamic Island,
/// status/navigation bars). Uses [MediaQuery.padding], matching [SafeArea].
EdgeInsets getPlatformSafeAreaPadding(BuildContext context) {
  return MediaQuery.paddingOf(context);
}

/// Top safe-area inset (status bar, notch, Dynamic Island).
double getPlatformTopPadding(BuildContext context) {
  return MediaQuery.paddingOf(context).top;
}

/// Bottom safe-area inset (home indicator, navigation bar).
double getPlatformBottomPadding(BuildContext context) {
  return MediaQuery.paddingOf(context).bottom;
}

/// Checks if the current platform is Android.
bool get isAndroid => Platform.isAndroid;

/// Checks if the current platform is iOS.
bool get isIOS => Platform.isIOS;
