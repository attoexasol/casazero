import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../data/models/hub_card_model.dart';

class HubCardWidget extends StatefulWidget {
  final HubCard card;
  final int index;
  final VoidCallback onTap;

  const HubCardWidget({
    Key? key,
    required this.card,
    required this.index,
    required this.onTap,
  }) : super(key: key);

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
                  gradient: LinearGradient(colors: widget.card.bgGradient),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            /// MAIN CONTENT
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),

                  const SizedBox(height: 12),

                  /// TITLE
                  Text(
                    widget.card.title,
                    textAlign: TextAlign.center,
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
          ],
        ),
      ).animate().fadeIn(delay: (100 + widget.index * 80).ms).slideY(begin: 0.3),
    );
  }

  /// ----------------------------------------------------------
  /// ICON BUILDER → Supports PNG/JPG/SVG + Fallback to IconData
  /// ----------------------------------------------------------
  Widget _buildIcon() {
    if (widget.card.isImage && widget.card.imagePath != null) {
      final path = widget.card.imagePath!.toLowerCase();
      print(widget.card.imagePath!);
      // SVG SUPPORT
      if (path.endsWith('.svg')) {
        return SvgPicture.asset(
          widget.card.imagePath!,
          width: 560,
          height: 560,
        );
      }

      // PNG/JPG/WEBP SUPPORT
      return Image.asset(
        widget.card.imagePath!,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
      );
    }

    // DEFAULT ICON WITH GRADIENT
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: widget.card.gradient),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        widget.card.icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
