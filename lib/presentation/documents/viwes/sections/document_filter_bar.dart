import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/document_category_model.dart';
import '../../../../core/localization/locale_controller.dart';
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
      // Get current language from LocaleController
      bool isItalian = false;
      try {
        final localeController = Get.find<LocaleController>();
        isItalian = localeController.isItalian;
      } catch (e) {
        // Fallback to English if LocaleController not available
      }

      // Always start with "All Categories" as first item
      final List<Map<String, dynamic>> categories = [
        {"id": "all", "label": "allCategories".tr, "count": totalDocumentCount},
      ];

      // Add categories from API with bilingual support
      for (var category in apiCategories) {
        // Select display name based on language with fallback
        final displayName = isItalian
            ? (category.categoryNameIt.isNotEmpty
                ? category.categoryNameIt
                : category.categoryName)
            : category.categoryName;

        // Use English name for ID to maintain filter consistency
        categories.add({
          "id": category.categoryName.toLowerCase(),
          "label": displayName,
          "count": category.count,
        });
      }

      // Show loading indicator if categories are being fetched
      if (isLoading) {
        return SizedBox(
          height: 48,
          child: Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF4CAF47),
              strokeWidth: 2,
            ),
          ),
        );
      }

      return SizedBox(
        height: 48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final c = categories[index];
            final isActive = c['id'] == activeCategory;
            final accentColor = documentCategoryColor(c['id'] as String);

            return GestureDetector(
              onTap: () => onCategoryChanged(c['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isActive ? Colors.transparent : Colors.grey.shade300,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: accentColor.withOpacity(.25),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(
                      "${c['label']}",
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isActive ? Colors.white.withOpacity(0.25) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        "${c['count']}",
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
