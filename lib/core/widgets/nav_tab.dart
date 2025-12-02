import 'package:flutter/material.dart';

class NavTab {
  final String id;
  final IconData? icon;
  final String label;
  final String? assetIcon;

  const NavTab({
    required this.id,
    this.icon,
    required this.label,
    this.assetIcon,
  });
}
