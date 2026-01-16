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
          return Stack(
            children: [
              // Bottom layer: API image (unchanged)
              CachedNetworkImage(
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
              ),
              // Top gradient overlay (top edge only - 25% of height)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 480 * 0.25, // 25% of image height
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.6),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom gradient overlay (bottom edge only - 30% of height)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 480 * 0.3, // 30% of image height
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white.withOpacity(0.7),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Fallback to existing asset image with same overlay effect
          return Stack(
            children: [
              // Bottom layer: Asset image (unchanged)
              Image.asset(
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
              // Top gradient overlay (top edge only - 25% of height)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 480 * 0.25, // 25% of image height
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.6),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom gradient overlay (bottom edge only - 30% of height)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 480 * 0.3, // 30% of image height
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white.withOpacity(0.7),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
