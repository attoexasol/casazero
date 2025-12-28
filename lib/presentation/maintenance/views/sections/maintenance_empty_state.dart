// presentation/maintenance/views/sections/maintenance_empty_state.dart
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class MaintenanceEmptyState extends StatelessWidget {
  final String title;
  final String description;

  const MaintenanceEmptyState({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.neutralInk300,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutralInk900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                //color: AppColors.neutralInk600,
                color: AppColors.neutralInk700
              ),
            ),
          ],
        ),
      ),
    );
  }
}




