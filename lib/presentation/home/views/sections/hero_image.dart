import 'package:flutter/material.dart';

class HeroImage extends StatelessWidget {
  const HeroImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      width: double.infinity, // Full width
      height: 480, // Fixed height to ensure image is visible
      child: Image.asset(
        'assets/images/residence_hero.jpeg',
        width: double.infinity, // Full width
        height: 480, // Match container height
        fit: BoxFit.cover, // Cover the entire container
        errorBuilder: (context, error, stackTrace) {
          // Fallback if asset image fails to load
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
  }
}
