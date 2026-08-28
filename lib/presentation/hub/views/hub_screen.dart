import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/widgets/floating_bottom_nav_bar.dart';
import '../controllers/hub_controller.dart';
import 'sections/hub_card_widget.dart';
import '../../../core/logging/diagnostic_logger.dart';

class HubScreen extends GetView<HubController> {
  final Function(String) onNavigate;

  const HubScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final hubCards = controller.hubCards;

    DiagnosticLogger.instance.debug('🔍 HubScreen: Showing ${hubCards.length} cards out of 4 total');
    for (var card in hubCards) {
      DiagnosticLogger.instance.debug('  - ${card.title} (${card.id})');
    }

    if (hubCards.isEmpty) {
      return SingleChildScrollView(
        padding: FloatingBottomNavBar.screenPadding(context),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.r),
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
                    style: TextStyle(
                      fontSize: 18.sp,
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
          padding: FloatingBottomNavBar.screenPadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width >= 600 ? 840.w : double.infinity,
              ),
              child: Column(
                children: [
                  SizedBox(height: 30.h),
              // SizedBox(
              //   height: width >= 600 ? 160 : 145,
              //   child: CasaZeroLogo(
              //     assetPath: 'assets/images/smart_area_logo.png',
              //     containerHeight: width >= 600 ? 130 : 110,
              //   )
              //       .animate()
              //       .scale(
              //         begin: const Offset(0.85, 0.85),
              //         end: const Offset(1.0, 1.0),
              //         duration: 600.ms,
              //         curve: Curves.easeOutCubic,
              //       )
              //       .fadeIn(
              //         duration: 500.ms,
              //         curve: Curves.easeOut,
              //       ),
              // ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width >= 600 ? 40 : 24,
                ),
                child:
                    Image.asset(
                          'assets/images/smart_area_logo.png',
                          height: width >= 600 ? 100 : 85,
                          fit: BoxFit.contain,
                        )
                        .animate()
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1.0, 1.0),
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(duration: 500.ms, curve: Curves.easeOut),
              ),
              SizedBox(height: 50.h),
              Padding(
                padding: horizontalPadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final isMobile = width < 600;
                    final isPyramid = isMobile && hubCards.length == 3;

                    if (isPyramid) {
                      final cardWidth = (availableWidth - 20) / 2;
                      final rawRatio = cardHeight > 0
                          ? cardWidth / cardHeight
                          : 1.0;
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
                    final rawRatio = cardHeight > 0
                        ? cardWidth / cardHeight
                        : 1.0;
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
              SizedBox(height: 52.h),
              Padding(padding: horizontalPadding, child: _buildInfoBanner()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF8E6), Color(0xFFF3FBEA)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF6B8E23).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B8E23), Color(0xFF9ACD32)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'exploreFeatures'.tr,
              style: TextStyle(fontSize: 13.sp, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}
