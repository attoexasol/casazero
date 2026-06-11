import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/widgets/casazero_logo.dart';
import '../../../core/widgets/floating_bottom_nav_bar.dart';
import '../controllers/hub_controller.dart';
import 'sections/hub_card_widget.dart';

class HubScreen extends GetView<HubController> {
  final Function(String) onNavigate;

  const HubScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final hubCards = controller.hubCards;

    print('🔍 HubScreen: Showing ${hubCards.length} cards out of 4 total');
    for (var card in hubCards) {
      print('  - ${card.title} (${card.id})');
    }

    if (hubCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                const Icon(
                  Icons.dashboard_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'noServicesAvailable'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'noServicesAvailableDesc'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gridCount = controller.getGridCount(width);
        final cardHeight = controller.getCardHeight(width);
        final horizontalPadding = controller.getHorizontalPadding(width);

        return SingleChildScrollView(
          padding: FloatingBottomNavBar.scrollBottomPadding(context),
          child: Column(
            children: [
              const SizedBox(height: 40),
              SizedBox(
                height: width >= 600 ? 160 : 145,
                child: CasaZeroLogo(
                  assetPath: 'assets/images/smart_area_logo.png',
                  containerHeight: width >= 600 ? 145 : 110,
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: horizontalPadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final isMobile = width < 600;
                    final isPyramid = isMobile && hubCards.length == 3;

                    if (isPyramid) {
                      final cardWidth = (availableWidth - 20) / 2;
                      final rawRatio = cardHeight > 0 ? cardWidth / cardHeight : 1.0;
                      final aspectRatio = rawRatio > 0 && rawRatio.isFinite
                          ? rawRatio
                          : 1.0;

                      return Column(
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: HubCardWidget(
                                card: hubCards[0],
                                index: 0,
                                onTap: () => onNavigate(hubCards[0].screen),
                                wrapIconInContainer:
                                    hubCards[0].wrapIconInContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: aspectRatio,
                                  child: HubCardWidget(
                                    card: hubCards[1],
                                    index: 1,
                                    onTap: () => onNavigate(hubCards[1].screen),
                                    wrapIconInContainer:
                                        hubCards[1].wrapIconInContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: aspectRatio,
                                  child: HubCardWidget(
                                    card: hubCards[2],
                                    index: 2,
                                    onTap: () => onNavigate(hubCards[2].screen),
                                    wrapIconInContainer:
                                        hubCards[2].wrapIconInContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    final cardWidth =
                        (availableWidth - (gridCount - 1) * 20) / gridCount;
                    final rawRatio = cardHeight > 0 ? cardWidth / cardHeight : 1.0;
                    final aspectRatio = rawRatio > 0 && rawRatio.isFinite
                        ? rawRatio
                        : 1.0;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: hubCards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (_, index) {
                        return HubCardWidget(
                          card: hubCards[index],
                          index: index,
                          onTap: () => onNavigate(hubCards[index].screen),
                          wrapIconInContainer:
                              hubCards[index].wrapIconInContainer,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                  padding: horizontalPadding, child: _buildInfoBanner()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF8E6), Color(0xFFF3FBEA)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF6B8E23).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B8E23), Color(0xFF9ACD32)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'exploreFeatures'.tr,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}
