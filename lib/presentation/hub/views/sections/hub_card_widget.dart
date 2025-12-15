import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/models/hub_card_model.dart';

class HubCardWidget extends StatefulWidget {
  final HubCard card;
  final int index;
  final VoidCallback onTap;
  final bool wrapIconInContainer;

  const HubCardWidget({
    super.key,
    required this.card,
    required this.index,
    required this.onTap,
    required this.wrapIconInContainer,
  });

  @override
  State<HubCardWidget> createState() => _HubCardWidgetState();
}

class _HubCardWidgetState extends State<HubCardWidget> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => hovered = true),
      onTapUp: (_) {
        setState(() => hovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hovered
                ? widget.card.hoverColor.withOpacity(0.4)
                : Colors.grey.shade200,
            width: hovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.card.shadowColor,
              blurRadius: hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            /// HOVER BACKGROUND GRADIENT
            AnimatedOpacity(
              duration: 200.ms,
              opacity: hovered ? 0.3 : 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.card.bgGradient,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            /// MAIN CONTENT
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 12),
                    /// TITLE
                    Text(
                      widget.card.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: hovered
                            ? widget.card.hoverColor
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (100 + widget.index * 80).ms)
          .slideY(begin: 0.3),
    );
  }

  /// ----------------------------------------------------------
  /// ICON BUILDER → Supports PNG/JPG/SVG + Fallback to IconData
  /// ----------------------------------------------------------
  Widget _buildIcon() {
    final path = widget.card.imagePath?.toLowerCase();

    // 🔹 FIRST CARD STYLE (no container) - larger icon
    if (!widget.card.wrapIconInContainer) {
      return _buildRawIcon(path, iconSize: 55);
    }

    // 🔹 OTHER CARDS (icon inside container) - smaller icon
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: widget.card.gradient),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: _buildRawIcon(path, forceWhite: true, iconSize: 25)),
    );
  }

  Widget _buildRawIcon(String? path, {bool forceWhite = false, double iconSize = 28}) {
    // SVG
    if (path != null && path.endsWith('.svg')) {
      return SvgPicture.asset(
        widget.card.imagePath!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        colorFilter: forceWhite
            ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
            : null,
        placeholderBuilder: (context) => Icon(
          widget.card.icon ?? Icons.home_outlined,
          size: iconSize,
          color: forceWhite ? Colors.white : Colors.black87,
        ),
      );
    }

    // PNG / JPG
    if (path != null) {
      return Image.asset(
        widget.card.imagePath!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        color: forceWhite ? Colors.white : null,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(
            widget.card.icon ?? Icons.image_not_supported,
            size: iconSize,
            color: forceWhite ? Colors.white : Colors.black87,
          );
        },
      );
    }

    // IconData fallback
    return Icon(
      widget.card.icon ?? Icons.dashboard,
      size: iconSize,
      color: forceWhite ? Colors.white : Colors.black87,
    );
  }
}
