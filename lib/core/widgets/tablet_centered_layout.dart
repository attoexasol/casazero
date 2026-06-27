import 'package:flutter/material.dart';

/// Centers content on wide screens and caps maximum width without
/// affecting phone layouts.
class TabletCenteredLayout extends StatelessWidget {
  const TabletCenteredLayout({
    super.key,
    required this.child,
    this.tabletBreakpoint = 600,
    this.tabletMaxWidth = 600,
  });

  final Widget child;
  final double tabletBreakpoint;
  final double tabletMaxWidth;

  static double contentMaxWidth(
    double availableWidth, {
    double tabletBreakpoint = 600,
    double tabletMaxWidth = 600,
  }) {
    if (availableWidth >= tabletBreakpoint) return tabletMaxWidth;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = contentMaxWidth(
          constraints.maxWidth,
          tabletBreakpoint: tabletBreakpoint,
          tabletMaxWidth: tabletMaxWidth,
        );

        if (maxW == double.infinity) {
          return child;
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,
              maxHeight: constraints.maxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
