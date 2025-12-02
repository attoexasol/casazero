import 'package:flutter/material.dart';

class AppAnimations {
  // Animation Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Animation Curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve spring = Curves.elasticOut;

  // Fade In Animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Scale In Animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Slide In From Right
  static Widget slideInFromRight({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * value, 0),
          child: Opacity(
            opacity: 1 - value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Slide In From Left
  static Widget slideInFromLeft({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-20 * value, 0),
          child: Opacity(
            opacity: 1 - value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}