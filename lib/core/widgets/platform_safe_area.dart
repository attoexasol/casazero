// core/widgets/platform_safe_area.dart
// Platform-specific SafeArea widget - applies only on Android, not iOS

import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// A SafeArea widget that applies only on Android devices.
///
/// iOS devices handle safe areas naturally through the system,
/// but Android devices need explicit SafeArea handling.
///
/// Usage:
/// ```dart
/// PlatformSafeArea(
///   child: YourWidget(),
/// )
/// ```
///
/// This is already applied globally in main.dart builder,
/// but can be used in specific screens if needed for additional control.
class PlatformSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;

  const PlatformSafeArea({
    Key? key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = false,
    this.right = false,
    this.minimum = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only apply SafeArea on Android
    if (Platform.isAndroid) {
      return SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        minimum: minimum,
        child: child,
      );
    }

    // iOS - Return child without SafeArea
    return child;
  }
}

/// A SafeArea widget that ONLY handles the top safe area on Android.
///
/// Useful for screens that need top padding but not bottom padding.
///
/// Usage:
/// ```dart
/// PlatformSafeArea.topOnly(
///   child: YourWidget(),
/// )
/// ```
class PlatformSafeAreaTop extends StatelessWidget {
  final Widget child;
  final EdgeInsets minimum;

  const PlatformSafeAreaTop({
    Key? key,
    required this.child,
    this.minimum = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return SafeArea(
        top: true,
        bottom: false,
        left: false,
        right: false,
        minimum: minimum,
        child: child,
      );
    }
    return child;
  }
}

/// A SafeArea widget that ONLY handles the bottom safe area on Android.
///
/// Useful for screens with bottom navigation or floating buttons.
///
/// Usage:
/// ```dart
/// PlatformSafeArea.bottomOnly(
///   child: YourWidget(),
/// )
/// ```
class PlatformSafeAreaBottom extends StatelessWidget {
  final Widget child;
  final EdgeInsets minimum;

  const PlatformSafeAreaBottom({
    Key? key,
    required this.child,
    this.minimum = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return SafeArea(
        top: false,
        bottom: true,
        left: false,
        right: false,
        minimum: minimum,
        child: child,
      );
    }
    return child;
  }
}

/// Gets the platform-specific safe area padding.
/// Returns actual padding on Android, zero padding on iOS.
///
/// Usage:
/// ```dart
/// final padding = getPlatformSafeAreaPadding(context);
/// ```
EdgeInsets getPlatformSafeAreaPadding(BuildContext context) {
  if (Platform.isAndroid) {
    return MediaQuery.of(context).padding;
  }
  return EdgeInsets.zero;
}

/// Gets only the top safe area padding.
/// Returns actual top padding on Android, zero on iOS.
double getPlatformTopPadding(BuildContext context) {
  if (Platform.isAndroid) {
    return MediaQuery.of(context).padding.top;
  }
  return 0.0;
}

/// Gets only the bottom safe area padding.
/// Returns actual bottom padding on Android, zero on iOS.
double getPlatformBottomPadding(BuildContext context) {
  if (Platform.isAndroid) {
    return MediaQuery.of(context).padding.bottom;
  }
  return 0.0;
}

/// Checks if the current platform is Android.
bool get isAndroid => Platform.isAndroid;

/// Checks if the current platform is iOS.
bool get isIOS => Platform.isIOS;