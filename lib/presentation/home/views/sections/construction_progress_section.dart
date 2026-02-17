// lib/presentation/home/views/sections/construction_progress_section.dart
// Demo-controlled Construction Progress. UI matches design: card radius 24,
// vertical aqua timeline, 42px circles, step cards with status.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../data/models/construction_phase_model.dart';

/// Placeholder phases with optional date for display.
List<ConstructionPhaseModel> _placeholderPhases() => [
  ConstructionPhaseModel(
    id: '1',
    name: 'Foundation',
    status: 'completed',
    progress: 100,
    startDate: DateTime(2025, 9, 1),
    endDate: DateTime(2025, 10, 15),
  ),
  ConstructionPhaseModel(
    id: '2',
    name: 'Structure',
    status: 'completed',
    progress: 100,
    startDate: DateTime(2025, 10, 20),
    endDate: DateTime(2025, 12, 1),
  ),
  ConstructionPhaseModel(
    id: '3',
    name: 'Facades',
    status: 'in-progress',
    progress: 65,
    startDate: DateTime(2026, 1, 10),
  ),
  ConstructionPhaseModel(
    id: '4',
    name: 'Finishes',
    status: 'pending',
    progress: 0,
    startDate: null,
  ),
];

/// Sparkles: very subtle rotation, smooth and slow.
double _sparkleDegrees(double t) {
  if (t <= 0.0) return 0;
  if (t <= 0.25) return 10 * t * 4;
  if (t <= 0.5) return 10 - 20 * (t - 0.25) * 4;
  if (t <= 0.75) return -10 + 10 * (t - 0.5) * 4;
  return 0;
}

// Soft aqua for line and accents (not strong green).
const Color _timelineLineColor = AppColors.aquaGreen200;
const Color _circleAquaFill = AppColors.aquaGreen500;
const Color _circleAquaLight = AppColors.aquaGreen100;
const Color _circleGrey = AppColors.neutralLine200;
const double _circleDiameter = 42;
const double _lineWidth = 2;
const double _stepSpacing = 24;
const double _indicatorWidth = 42;
const double _timelineRowHeight = 88;

/// Vertical line + circular node. Line does not extend beyond first/last circle.
/// [rowHeight] is required so we avoid LayoutBuilder (incompatible with IntrinsicHeight).
class _TimelineIndicator extends StatelessWidget {
  const _TimelineIndicator({
    required this.isFirst,
    required this.isLast,
    required this.status,
    required this.rowHeight,
  });

  final bool isFirst;
  final bool isLast;
  final String status;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final centerY = rowHeight / 2;
    final radius = _circleDiameter / 2;

    return SizedBox(
      width: _indicatorWidth,
      height: rowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (_indicatorWidth - _lineWidth) / 2,
            top: isFirst ? centerY : 0,
            bottom: isLast ? rowHeight - centerY : 0,
            width: _lineWidth,
            child: Container(color: _timelineLineColor),
          ),
          Positioned(
            left: (_indicatorWidth - _circleDiameter) / 2,
            top: centerY - radius,
            child: _TimelineCircle(status: status),
          ),
        ],
      ),
    );
  }
}

/// Circle: completed = filled aqua + white icon; in-progress = aqua border + light aqua bg; pending = grey.
class _TimelineCircle extends StatelessWidget {
  const _TimelineCircle({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    final isActive = status == 'in-progress';
    final isFuture = status == 'pending';

    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData iconData;
    double elevation;

    if (isCompleted) {
      bgColor = _circleAquaFill;
      borderColor = _circleAquaFill;
      iconColor = AppColors.surfaceWhite;
      iconData = Icons.check;
      elevation = 1;
    } else if (isActive) {
      bgColor = _circleAquaLight;
      borderColor = _circleAquaFill;
      iconColor = _circleAquaFill;
      iconData = Icons.build;
      elevation = 2;
    } else {
      bgColor = _circleGrey;
      borderColor = _circleGrey;
      iconColor = AppColors.neutralInk400;
      iconData = Icons.schedule;
      elevation = 0;
    }

    return Container(
      width: _circleDiameter,
      height: _circleDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        boxShadow: [
          if (elevation > 0)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }
}

/// Step card: rounded rect, padding 16–18, title left, date below, status right.
class _StepCard extends StatelessWidget {
  const _StepCard({required this.phase});

  final ConstructionPhaseModel phase;

  @override
  Widget build(BuildContext context) {
    final isCompleted = phase.status == 'completed';
    final isActive = phase.status == 'in-progress';
    final isFuture = phase.status == 'pending';

    String statusLabel;
    if (isCompleted)
      statusLabel = 'completed'.tr;
    else if (isActive)
      statusLabel = 'inProgressStatus'.tr;
    else
      statusLabel = 'pending'.tr;

    final dateStr = phase.startDate != null
        ? '${phase.startDate!.day}/${phase.startDate!.month}/${phase.startDate!.year}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? _circleAquaFill : AppColors.neutralLine100,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isActive ? 0.08 : 0.04),
            blurRadius: isActive ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  phase.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isFuture
                        ? AppColors.neutralInk500
                        : AppColors.neutralInk900,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutralInk500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCompleted || isActive)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _circleAquaFill,
                  ),
                ),
              Text(
                statusLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isFuture
                      ? AppColors.neutralInk400
                      : AppColors.neutralInk500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Construction Progress section - pixel-accurate to design.
class ConstructionProgressSection extends StatefulWidget {
  const ConstructionProgressSection({super.key, required this.onViewBuildings});

  final VoidCallback onViewBuildings;

  @override
  State<ConstructionProgressSection> createState() =>
      _ConstructionProgressSectionState();
}

class _ConstructionProgressSectionState
    extends State<ConstructionProgressSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phases = _placeholderPhases();

    return Container(
          margin: const EdgeInsets.only(top: 32, left: 24, right: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.neutralLine100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment.topRight,
                            radius: 0.8,
                            colors: [
                              AppColors.aquaGreen100.withOpacity(0.3),
                              AppColors.aquaGreen100.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'construction_progress'.tr,
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.neutralInk900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedBuilder(
                            animation: _sparkleController,
                            builder: (context, child) {
                              final t = _sparkleController.value;
                              final deg = t <= 0.4
                                  ? _sparkleDegrees(t / 0.4)
                                  : 0.0;
                              return Transform.rotate(
                                angle: deg * 3.1415926535 / 180,
                                child: child,
                              );
                            },
                            child: const Icon(
                              Icons.auto_awesome,
                              color: AppColors.aquaGreen500,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'your_home_is_being_built'.tr,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutralInk500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Timeline: Row(TimelineIndicator, SizedBox(16), Expanded(StepCard)) per phase.
                      // Fixed row height to avoid IntrinsicHeight + LayoutBuilder (unsupported).
                      ...phases.asMap().entries.map((entry) {
                        final index = entry.key;
                        final phase = entry.value;
                        final isFirst = index == 0;
                        final isLast = index == phases.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isLast ? 0 : _stepSpacing,
                          ),
                          child: SizedBox(
                            height: _timelineRowHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TimelineIndicator(
                                  isFirst: isFirst,
                                  isLast: isLast,
                                  status: phase.status,
                                  rowHeight: _timelineRowHeight,
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: _StepCard(phase: phase)),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      // SizedBox(
                      //   width: double.infinity,
                      //   height: 48,
                      //   child: Material(
                      //     color: AppColors.aquaGreen600,
                      //     borderRadius: BorderRadius.circular(12),
                      //     elevation: 1,
                      //     shadowColor: Colors.black.withOpacity(0.06),
                      //     child: InkWell(
                      //       onTap: widget.onViewBuildings,
                      //       borderRadius: BorderRadius.circular(12),
                      //       child: Padding(
                      //         padding: const EdgeInsets.symmetric(
                      //           horizontal: 16,
                      //         ),
                      //         child: Row(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             const Icon(
                      //               Icons.business,
                      //               size: 16,
                      //               color: AppColors.surfaceWhite,
                      //             ),
                      //             const SizedBox(width: 8),
                      //             Text(
                      //               'view_all_buildings'.tr,
                      //               style: AppTextStyles.button.copyWith(
                      //                 color: AppColors.surfaceWhite,
                      //                 fontSize: 16,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
