import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  int _crossAxisCount(double width) {
    if (width < 320) return 1;
    return 2;
  }

  double _childAspectRatio(double width, int crossAxisCount) {
    final horizontalPadding = 24.w * 2;
    final spacing = 16.w * (crossAxisCount - 1);
    final tileWidth = (width - horizontalPadding - spacing) / crossAxisCount;
    final tileHeight = tileWidth * 1.05;
    return tileWidth / tileHeight;
  }

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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = _crossAxisCount(screenWidth);

    return Padding(
      padding: EdgeInsets.only(top: 32.h, left: 24.w, right: 24.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: _childAspectRatio(screenWidth, crossAxisCount),
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
