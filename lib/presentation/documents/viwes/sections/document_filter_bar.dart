import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/widgets/category_filter_bar.dart';
import '../../../../data/models/document_category_model.dart';
import 'document_colors.dart';

class DocumentFilterBar extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onCategoryChanged;
  final List<DocumentCategoryModel> apiCategories;
  final bool isLoading;
  final int totalDocumentCount;

  const DocumentFilterBar({
    super.key,
    required this.activeCategory,
    required this.onCategoryChanged,
    this.apiCategories = const [],
    this.isLoading = false,
    this.totalDocumentCount = 0,
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
          count: totalDocumentCount,
        ),
      ];

      for (final category in apiCategories) {
        final displayName = isItalian
            ? (category.categoryNameIt.isNotEmpty
                ? category.categoryNameIt
                : category.categoryName)
            : category.categoryName;

        items.add(
          FilterBarItem(
            id: category.categoryName.toLowerCase(),
            label: displayName,
            count: category.count,
          ),
        );
      }

      return CategoryFilterBar(
        activeId: activeCategory,
        onSelected: onCategoryChanged,
        items: items,
        isLoading: isLoading,
        colorForId: documentCategoryColor,
      );
    });
  }
}
