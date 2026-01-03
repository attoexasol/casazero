import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';

class HeroImage extends StatelessWidget {
  const HeroImage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final residencePhoto = controller.residenceData.value?['residence_photo'];
      
      return Container(
        margin: const EdgeInsets.only(top: 05),
        height: 480,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: residencePhoto != null && residencePhoto.isNotEmpty
                ? NetworkImage(residencePhoto) as ImageProvider
                : const AssetImage('assets/images/residence_hero.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    });
  }
}
