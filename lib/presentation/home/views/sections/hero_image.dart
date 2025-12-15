import 'package:flutter/material.dart';

class HeroImage extends StatelessWidget {
  const HeroImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top:05),
      height: 480,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/residence_hero.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
