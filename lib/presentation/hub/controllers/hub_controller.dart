import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/permissions.dart';
import '../../../data/models/hub_card_model.dart';
import '../../home/controllers/home_controller.dart';

/// Controller for HubScreen. Holds hub cards and responsive layout logic.
class HubController extends GetxController {
  List<HubCard> get hubCards {
    final role = Get.find<HomeController>().currentUser.value?.role ?? Role.client;
    final permissions = Permissions.fromRole(role);
    return [
      HubCard(
        id: 'ai',
        screen: 'aichat',
        title: 'casaZeroAICard'.tr,
        isImage: true,
        imagePath: "assets/images/thumb_cubo.png",
        gradient: const [Color(0xFF6B8E23), Color(0xFF9ACD32)],
        bgGradient: const [Color(0xFFEFF8E6), Color(0xFFF3FBEA)],
        shadowColor: const Color(0x4D4CAF47),
        hoverColor: const Color(0xFF4CAF47),
        show: permissions.canAccessAI,
        wrapIconInContainer: false,
      ),
      HubCard(
        id: 'chat',
        screen: 'chat',
        title: 'chatCondominio'.tr,
        imagePath: "assets/images/Chat_icon.svg",
        gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
        bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        shadowColor: const Color(0x4D3B82F6),
        hoverColor: const Color(0xFF3B82F6),
        show: permissions.canAccessChat,
        wrapIconInContainer: true,
      ),
      HubCard(
        id: 'assistenza',
        screen: 'tickets',
        title: 'assistenza'.tr,
        icon: Icons.help_outline,
        gradient: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
        bgGradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        shadowColor: const Color(0x4DF59E0B),
        hoverColor: const Color(0xFFF59E0B),
        show: permissions.canCreateTickets,
        wrapIconInContainer: true,
      ),
    ].where((c) => c.show).toList();
  }

  int getGridCount(double width) {
    if (width >= 1100) return 4;
    if (width >= 800) return 3;
    if (width >= 600) return 2;
    return 2;
  }

  double getCardHeight(double width) {
    if (width >= 1100) return 220;
    if (width >= 800) return 200;
    if (width >= 600) return 180;
    return 160;
  }

  EdgeInsets getHorizontalPadding(double width) {
    if (width >= 1100) return const EdgeInsets.symmetric(horizontal: 120);
    if (width >= 800) return const EdgeInsets.symmetric(horizontal: 80);
    if (width >= 600) return const EdgeInsets.symmetric(horizontal: 40);
    return const EdgeInsets.symmetric(horizontal: 24);
  }
}
