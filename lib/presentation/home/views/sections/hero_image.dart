import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/home_controller.dart';
import '../../../../core/utils/image_url_builder.dart';

class HeroImage extends StatelessWidget {
  const HeroImage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Container(
      margin: const EdgeInsets.only(top: 5),
      width: double.infinity, // Full width
      height: 480, // Fixed height to ensure image is visible
      child: Obx(() {
        final residencePhoto = controller.residenceData.value?['residence_photo'];
        final imageUrl = ImageUrlBuilder.buildResidenceImageUrl(residencePhoto);
        
        // Use API image if available, otherwise fallback to asset
        if (imageUrl.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: 480,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: double.infinity,
              height: 480,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Image.asset(
              'assets/images/residence_hero.jpeg',
              width: double.infinity,
              height: 480,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 480,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          // Fallback to existing asset image
          return Image.asset(
            'assets/images/residence_hero.jpeg',
            width: double.infinity,
            height: 480,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 480,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          );
        }
      }),
    );
  }
}
