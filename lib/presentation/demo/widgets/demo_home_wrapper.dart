// lib/presentation/demo/widgets/demo_home_wrapper.dart
// Isolated wrapper: adds Demo button + right-slide panel overlay on top of existing child.
// Does not modify any existing behavior. Registers DemoController only when used.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/demo_controller.dart';
import 'demo_button.dart';
import '../views/demo_controls_panel.dart';

/// Wraps Home screen content with a Stack and overlays:
/// - Demo button (top-right)
/// - Right-sliding panel + dimmer when open.
/// DemoController is put here if not registered (no binding change).
class DemoHomeWrapper extends StatelessWidget {
  const DemoHomeWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DemoController>()) {
      Get.put(DemoController(), permanent: false);
    }
    final demoCtrl = Get.find<DemoController>();

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            left: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 16),
              child: const DemoButton(),
            ),
          ),
        ),
        Obx(() {
          if (!demoCtrl.isPanelOpen.value) return const SizedBox.shrink();
          return Positioned.fill(
            child: GestureDetector(
              onTap: demoCtrl.closePanel,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          );
        }),
        Obx(() {
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            right: demoCtrl.isPanelOpen.value ? 0 : -320,
            top: 0,
            bottom: 0,
            width: 320,
            child: const DemoControlsPanel(),
          );
        }),
      ],
    );
  }
}
