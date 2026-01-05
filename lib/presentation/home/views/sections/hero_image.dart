import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/home_controller.dart';

class HeroImage extends StatelessWidget {
  const HeroImage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final residencePhoto = controller.residenceData.value?['residence_photo'];
      
      // Debug: Log image URL
      if (residencePhoto != null && residencePhoto.isNotEmpty) {
        print('🏠 [HeroImage] Residence photo URL: $residencePhoto');
      }
      
      return Container(
        margin: const EdgeInsets.only(top: 05),
        height: 480,
        child: residencePhoto != null && residencePhoto.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: residencePhoto,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/images/residence_hero.png',
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                'assets/images/residence_hero.png',
                fit: BoxFit.cover,
              ),
      );
    });
  }
}
