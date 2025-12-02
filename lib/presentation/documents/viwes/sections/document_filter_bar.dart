import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DocumentFilterBar extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onCategoryChanged;

  const DocumentFilterBar({
    super.key,
    required this.activeCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      {"id": "all", "label": "allCategories".tr, "count": 41},
      {"id": "mydocuments", "label": "myDocuments".tr, "count": 3},
      {"id": "ownership", "label": "ownershipLegal".tr, "count": 5},
      {"id": "technical", "label": "technicalBuilding".tr, "count": 8},
      {"id": "energy", "label": "energyEnvironmental".tr, "count": 10},
      {"id": "compliance", "label": "complianceSafety".tr, "count": 7},
      {"id": "administrative", "label": "administrativeMaintenance".tr, "count": 11},
    ];

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

          return GestureDetector(
            onTap: () => onCategoryChanged(c['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF4CAF47) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isActive ? Colors.transparent : Colors.grey.shade300,
                ),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF47).withOpacity(.25),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.25)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      "${c['count']}",
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
