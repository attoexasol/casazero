import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer' as developer;
import '../../controllers/home_controller.dart';
import '../../../../core/utils/image_url_builder.dart';

class HeroImage extends StatelessWidget {
  const HeroImage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final residencePhoto = controller.residenceData.value?['residence_photo'];
      
      // Build safe image URL using utility
      final imageUrl = ImageUrlBuilder.buildResidenceImageUrl(
        residencePhoto?.toString(),
      );
      
      return Container(
        margin: const EdgeInsets.only(top: 5),
        width: double.infinity, // Full width
        constraints: const BoxConstraints(
          minHeight: 200,
          maxHeight: 600,
        ),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity, // Full width
                fit: BoxFit.fitWidth, // Fit width without cropping, maintain aspect ratio
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: 400,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) {
                  // Log error for debugging (temporary)
                  developer.log(
                    '[IMAGE] Error loading image from URL: $url',
                    name: 'HeroImage',
                    error: error,
                  );
                  // Gracefully fall back to asset image
                  developer.log(
                    '[IMAGE] Placeholder rendered due to invalid URL',
                    name: 'HeroImage',
                  );
                  return Image.asset(
                    'assets/images/residence_hero.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  );
                },
              )
            : Image.asset(
                'assets/images/residence_hero.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
      );
    });
  }
}
