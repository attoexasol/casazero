import 'package:flutter/material.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';

class ResidenceName extends StatelessWidget {
  final dynamic user;

  const ResidenceName({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final residenceName = controller.residenceData.value?['residence_name'] ?? 
                          user?.fullName ?? 
                          'Villa';
      return Padding(
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        child: Text(
          residenceName,
          textAlign: TextAlign.center,
          style: AppTextStyles.h2.copyWith(
            fontSize: 28,
            letterSpacing: -0.7,
          ),
        ),
      );
    });
  }
}
