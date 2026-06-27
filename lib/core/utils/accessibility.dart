import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared accessibility helpers for touch targets and text-scale-aware sizing.
abstract final class Accessibility {
  /// Material / WCAG recommended minimum interactive target (logical dp).
  static const double minTouchTarget = 48.0;

  static BoxConstraints get iconButtonConstraints => const BoxConstraints(
        minWidth: minTouchTarget,
        minHeight: minTouchTarget,
      );

  /// Button height floor that grows modestly with system text scale.
  static double buttonMinHeight(
    BuildContext context, {
    double base = minTouchTarget,
  }) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return math.max(base, base * scale).clamp(base, base * 1.35);
  }
}
