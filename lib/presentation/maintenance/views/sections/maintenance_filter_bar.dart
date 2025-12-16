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
      // Build filters list starting with "All"
      final filters = <Map<String, dynamic>>[
        {
          'id': 'all',
          'label': 'Tutte',
          'count': controller.totalTaskCount.value,
        },
      ];

      // Add category filters dynamically from API
      if (controller.categories.isNotEmpty) {
        for (final category in controller.categories) {
          final count = controller.categoryTaskCounts[category.id] ?? 0;
          filters.add({
            'id': 'category_${category.id}',
            'categoryId': category.id,
            'label': category.name,
            'count': count,
          });
        }
      } else {
        // Fallback to priority/status filters if categories are not loaded yet
        filters.addAll([
          {
            'id': 'personal',
            'label': 'Personal',
            'count': controller.personalCount.value,
          },
          {
            'id': 'facoltative',
            'label': 'Facoltative',
            'count': controller.facoltativeCount.value,
          },
          {
            'id': 'obbligatorie',
            'label': 'Obbligatorie',
            'count': controller.obbligatorieCount.value,
          },
          {
            'id': 'condominiali',
            'label': 'Condominiali',
            'count': controller.condominialiCount.value,
          },
          {
            'id': 'pending',
            'label': 'Pending',
            'count': controller.pendingCount.value,
          },
          {
            'id': 'overdue',
            'label': 'Scadute',
            'count': controller.overdueCount.value,
          },
        ]);
      }

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
                          filter['label'] as String,
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
                      // Update controller's selected category ID
                      if (filterId.startsWith('category_')) {
                        final categoryId = filter['categoryId'] as int?;
                        controller.setSelectedCategoryId(categoryId);
                      } else {
                        controller.setSelectedCategoryId(null); // "all" or other filters
                      }
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



