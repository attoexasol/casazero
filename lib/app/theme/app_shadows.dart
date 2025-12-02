import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0F000000), // rgba(0, 0, 0, 0.06)
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
      blurRadius: 15,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
      blurRadius: 25,
      offset: Offset(0, 20),
    ),
    BoxShadow(
      color: Color(0x05000000), // rgba(0, 0, 0, 0.02)
      blurRadius: 10,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> shadowPremium = [
    BoxShadow(
      color: Color(0x264CAF47), // rgba(76, 175, 71, 0.15)
      blurRadius: 50,
      offset: Offset(0, 25),
    ),
  ];

  static const List<BoxShadow> shadowGlow = [
    BoxShadow(
      color: Color(0x264CAF47), // rgba(76, 175, 71, 0.15)
      blurRadius: 20,
      offset: Offset(0, 0),
    ),
  ];

  static List<BoxShadow> customColoredShadow(Color color, {double opacity = 0.08}) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
