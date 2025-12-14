import 'package:flutter/material.dart';

class HubCard {
  final String id;
  final String screen;
  final String title;
  final IconData? icon;
  final bool isImage;
  final String? imagePath;
  final List<Color> gradient;
  final List<Color> bgGradient;
  final Color shadowColor;
  final Color hoverColor;
  final bool show;
  final bool wrapIconInContainer;

  HubCard({
    required this.id,
    required this.screen,
    required this.title,
    this.icon,
    this.isImage = false,
    this.imagePath,
    required this.gradient,
    required this.bgGradient,
    required this.shadowColor,
    required this.hoverColor,
    required this.show,
    this.wrapIconInContainer = true,
  });
}
