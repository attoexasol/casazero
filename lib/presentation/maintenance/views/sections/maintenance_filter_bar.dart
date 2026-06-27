// presentation/maintenance/views/sections/maintenance_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/widgets/category_filter_bar.dart';
import '../../../documents/viwes/sections/document_colors.dart';
import '../../models/maintenance_category_model.dart';
import '../../controllers/maintenance_controller.dart';

class MaintenanceFilterBar extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final List<MaintenanceCategory> apiCategories;
  final Map<int, int> categoryCounts;
  final bool isLoading;
  final int totalTaskCount;

  const MaintenanceFilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    this.apiCategories = const [],
    this.categoryCounts = const {},
    this.isLoading = false,
    this.totalTaskCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool isItalian = false;
      try {
        final localeController = Get.find<LocaleController>();
        isItalian = localeController.isItalian;
      } catch (_) {}

      final items = <FilterBarItem>[
        FilterBarItem(
          id: 'all',
          label: 'allCategories'.tr,
          count: totalTaskCount,
        ),
      ];

      for (final category in apiCategories) {
        final displayName = isItalian
            ? (category.name.isNotEmpty
                ? category.name
                : category.nameEn)
            : (category.nameEn.isNotEmpty
                ? category.nameEn
                : category.name);

        items.add(
          FilterBarItem(
            id: 'category_${category.id}',
            label: displayName.isNotEmpty
                ? displayName
                : 'Category ${category.id}',
            count: categoryCounts[category.id] ?? 0,
          ),
        );
      }

      return CategoryFilterBar(
        activeId: activeFilter,
        onSelected: (filterId) {
          final controller = Get.find<MaintenanceController>();
          if (filterId == 'all') {
            controller.setSelectedCategoryId(null);
          } else if (filterId.startsWith('category_')) {
            final categoryId =
                int.tryParse(filterId.substring('category_'.length));
            controller.setSelectedCategoryId(categoryId);
          }
          onFilterChanged(filterId);
        },
        items: items,
        isLoading: isLoading,
        showActiveShadow: false,
        colorForId: (id) {
          if (id == 'all') return documentCategoryColor('all');
          final item = items.firstWhere(
            (item) => item.id == id,
            orElse: () => items.first,
          );
          return documentCategoryColor(item.label);
        },
      );
    });
  }
}
