// presentation/maintenance/views/sections/maintenance_filter_bar.dart
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/maintenance_controller.dart';

class MaintenanceFilterBar extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  const MaintenanceFilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MaintenanceController>();

    return Obx(() {
      // Get filter list from controller (includes [All] + categories)
      final filters = controller.buildFilterList();

      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite.withOpacity(0.95),
          border: Border(
            bottom: BorderSide(color: AppColors.neutralLine200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: filters.map((filter) {
                final isActive = activeFilter == filter['id'];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isActive,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (filter['label'] as String? ?? '').toString(),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? AppColors.surfaceWhite
                                : AppColors.neutralInk700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.surfaceWhite.withOpacity(0.2)
                                : AppColors.neutralLine200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${filter['count']}',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.surfaceWhite
                                  : AppColors.neutralInk700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.surfaceWhite,
                    selectedColor: AppColors.brandSage600,
                    side: BorderSide(
                      color: isActive
                          ? AppColors.brandSage400
                          : AppColors.neutralLine200,
                    ),
                    onSelected: (selected) {
                      final filterId = filter['id'] as String;
                      // Update controller's selected category ID (controller handles filtering)
                      if (filterId == 'all') {
                        controller.setSelectedCategoryId(null); // "All" selected
                      } else if (filterId.startsWith('category_')) {
                        final categoryId = filter['categoryId'] as int?;
                        controller.setSelectedCategoryId(categoryId);
                      }
                      // Notify parent widget of filter change
                      onFilterChanged(filterId);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    });
  }
}



