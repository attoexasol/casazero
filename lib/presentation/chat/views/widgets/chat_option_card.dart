import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Hub-style selectable card for chat entry options (group / admin).
class ChatOptionCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imagePath;
  final List<Color> gradient;
  final List<Color> bgGradient;
  final Color shadowColor;
  final Color hoverColor;
  final int index;
  final VoidCallback onTap;
  final bool wrapIconInContainer;

  const ChatOptionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imagePath,
    required this.gradient,
    required this.bgGradient,
    required this.shadowColor,
    required this.hoverColor,
    required this.index,
    required this.onTap,
    this.wrapIconInContainer = true,
  });

  @override
  State<ChatOptionCard> createState() => _ChatOptionCardState();
}

class _ChatOptionCardState extends State<ChatOptionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) {
        setState(() => _hovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: 200.ms,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? widget.hoverColor.withValues(alpha: 0.4)
                : Colors.grey.shade200,
            width: _hovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedOpacity(
              duration: 200.ms,
              opacity: _hovered ? 0.3 : 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: widget.bgGradient),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Row(
                children: [
                  _buildIcon(),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            color: _hovered
                                ? widget.hoverColor
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.35,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: _hovered ? widget.hoverColor : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (100 + widget.index * 80).ms)
          .slideY(begin: 0.2),
    );
  }

  Widget _buildIcon() {
    final path = widget.imagePath?.toLowerCase();

    if (!widget.wrapIconInContainer) {
      return _buildRawIcon(path, iconSize: 40.sp);
    }

    return Container(
      width: 56.w,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: widget.gradient),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: _buildRawIcon(path, forceWhite: true, iconSize: 26.sp),
      ),
    );
  }

  Widget _buildRawIcon(
    String? path, {
    bool forceWhite = false,
    double iconSize = 28,
  }) {
    if (path != null && path.endsWith('.svg')) {
      return SvgPicture.asset(
        widget.imagePath!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        colorFilter: forceWhite
            ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
            : null,
        placeholderBuilder: (context) => Icon(
          widget.icon ?? Icons.chat_bubble_outline,
          size: iconSize,
          color: forceWhite ? Colors.white : Colors.black87,
        ),
      );
    }

    if (path != null) {
      return Image.asset(
        widget.imagePath!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        color: forceWhite ? Colors.white : null,
        errorBuilder: (_, __, ___) => Icon(
          widget.icon ?? Icons.chat_bubble_outline,
          size: iconSize,
          color: forceWhite ? Colors.white : Colors.black87,
        ),
      );
    }

    return Icon(
      widget.icon ?? Icons.chat_bubble_outline,
      size: iconSize,
      color: forceWhite ? Colors.white : Colors.black87,
    );
  }
}
