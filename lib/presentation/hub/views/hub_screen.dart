import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/widgets/casazero_logo.dart';
import '../../../data/models/hub_card_model.dart';
import 'sections/hub_card_widget.dart';


class HubScreen extends StatelessWidget {
  final Role role;
  final Function(String) onNavigate;

  const HubScreen({
    super.key,
    required this.role,
    required this.onNavigate,
  });

  // -------------------------------
  // RESPONSIVE BREAKPOINTS
  // -------------------------------
  int _getGridCount(double width) {
    // For mobile, show 2 columns to ensure cards are visible
    // For larger screens, show more columns
    if (width >= 1100) return 4; // Desktop - show all 4 cards in one row
    if (width >= 800) return 3;  // Tablet Landscape - 3 columns
    if (width >= 600) return 2;  // Tablet Portrait - 2 columns
    return 2;                    // Mobile - 2 columns (cards will wrap to 2 rows)
  }

  double _getCardHeight(double width) {
    if (width >= 1100) return 220;
    if (width >= 800) return 200;
    if (width >= 600) return 180;
    return 160;
  }

  EdgeInsets _getHorizontalPadding(double width) {
    if (width >= 1100) return const EdgeInsets.symmetric(horizontal: 120);
    if (width >= 800) return const EdgeInsets.symmetric(horizontal: 80);
    if (width >= 600) return const EdgeInsets.symmetric(horizontal: 40);
    return const EdgeInsets.symmetric(horizontal: 24);
  }

  @override
  Widget build(BuildContext context) {
    final permissions = Permissions.fromRole(role);

    final hubCards = [
      HubCard(
        id: 'ai',
        screen: 'aichat',
        title: "CasaZero AI",
        isImage: true,
        imagePath: "assets/images/thumb_cubo.png",
        gradient: const [Color(0xFF6B8E23), Color(0xFF9ACD32)],
        bgGradient: const [Color(0xFFEFF8E6), Color(0xFFF3FBEA)],
        shadowColor: const Color(0x4D4CAF47),
        hoverColor: const Color(0xFF4CAF47),
        show: permissions.canAccessAI,
        wrapIconInContainer: false,
      ),
      HubCard(
        id: 'smarthome',
        screen: 'smarthome',
        title: "Domotica",
        //icon: Icons.home_outlined,
        imagePath: "assets/images/home.svg",
        gradient: const [Color(0xFFA855F7), Color(0xFF9333EA)],
        bgGradient: const [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
        shadowColor: const Color(0x4DA855F7),
        hoverColor: const Color(0xFF9333EA),
        show: permissions.canAccessSmartHome, // Now true for all roles
        wrapIconInContainer: true,
      ),
      HubCard(
        id: 'chat',
        screen: 'chat',
        title: "Chat Condominio",
        //icon: Icons.chat_outlined,
        imagePath: "assets/images/Chat_icon.svg",
        gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
        bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        shadowColor: const Color(0x4D3B82F6),
        hoverColor: const Color(0xFF3B82F6),
        show: permissions.canAccessChat,
        wrapIconInContainer: true,
      ),
      HubCard(
        id: 'assistenza',
        screen: 'tickets',
        title: "Assistenza",
        icon: Icons.help_outline,
        gradient: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
        bgGradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        shadowColor: const Color(0x4DF59E0B),
        hoverColor: const Color(0xFFF59E0B),
        show: permissions.canCreateTickets,
        wrapIconInContainer: true,
      ),
    ].where((c) => c.show).toList();
    
    // Debug: Print card count
    print('🔍 HubScreen: Showing ${hubCards.length} cards out of 4 total');
    for (var card in hubCards) {
      print('  - ${card.title} (${card.id})');
    }

    // Show empty state if no cards are available
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
              const Text(
                'No Services Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You don\'t have access to any services at the moment.',
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
        final gridCount = _getGridCount(width);
        final cardHeight = _getCardHeight(width);
        final horizontalPadding = _getHorizontalPadding(width);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // TOP LOGO
              SizedBox(
                height: width >= 600 ? 180 : 140,
                child:
                CasaZeroLogo(
                  assetPath: 'assets/images/green_logo.png',
                  //maxLogoWidthFactor:1,
                )
              ),

              const SizedBox(height: 10),

              // RESPONSIVE GRID
              Padding(
                padding: horizontalPadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate available width after padding
                    final availableWidth = constraints.maxWidth;
                    // Calculate card width (accounting for spacing)
                    final cardWidth = (availableWidth - (gridCount - 1) * 20) / gridCount;
                    // Calculate aspect ratio: width / height
                    final aspectRatio = cardWidth / cardHeight;
                    
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
                          wrapIconInContainer: hubCards[index].wrapIconInContainer,
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // INFO BANNER
              Padding(
                padding: horizontalPadding,
                child: _buildInfoBanner(),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------
  // LOGO HEADER
  // -------------------------------
  Widget _buildHeader(double width) {
    final size = width >= 600 ? 110.0 : 80.0;
    final glowSize = size * 1.6;
    final ringSize = size * 1.4;

    return Center(
      child: SizedBox(
        width: glowSize,
        height: glowSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: glowSize,
              height: glowSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6B8E23), Color(0xFF9ACD32)],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1),
              end: const Offset(1.12, 1.12),
              duration: 2.seconds,)
                .fade(begin: 0.3, end: 0.6),

            Image.asset(
              "assets/images/casazero_logo.png",
              height: size * 0.55,
            ).animate().fadeIn().scale(duration: 600.ms),

            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6B8E23).withOpacity(0.3),
                  width: 2,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1),
              end: const Offset(1.12, 1.12),
              duration: 2.seconds,)
                .fade(begin: 0.3, end: 0.5),
          ],
        ),
      ),
    );
  }

  // -------------------------------
  // INFO BANNER
  // -------------------------------
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
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Esplora tutte le funzionalità intelligenti di CasaZero per gestire la tua casa",
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

