import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/permissions.dart';
import 'quick_tile_item.dart';

class QuickTiles extends StatelessWidget {
  final Permissions permissions;
  final Function(String) onNavigate;

  const QuickTiles({
    super.key,
    required this.permissions,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Map<String, dynamic>>[];

    if (permissions.canAccessAnalytics) {
      tiles.add({
        'icon': Icons.bar_chart,
        'title': 'analytics'.tr,
        'label': 'residence_insights_desc'.tr,
        'screen': 'analytics'
      });
    }

    if (permissions.canViewUserList) {
      tiles.add({
        'icon': Icons.people,
        'title': 'residents'.tr,
        'label': 'manage_community_desc'.tr,
        'screen': 'users'
      });
    }

    if (permissions.canManageBuildings) {
      tiles.add({
        'icon': Icons.business,
        'title': 'building'.tr,
        'label': 'manage_buildings_desc'.tr,
        'screen': 'buildings'
      });
    }

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 32, left: 24, right: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, i) {
          return QuickTileItem(
            data: tiles[i],
            onTap: () => onNavigate(tiles[i]['screen']),
          )
              .animate(
            delay: (i * 120).ms,
          )
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.2);
        },
      ),
    );
  }
}
