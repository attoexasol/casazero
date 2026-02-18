// lib/presentation/home/views/sections/construction_progress_section.dart
// Construction Progress from API (status-with-phases). UI matches design: card radius 24,
// vertical aqua timeline, 42px circles, step cards with status; plus document view section.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../data/models/construction_phase_model.dart';
import '../../../../data/models/residence_status_phase_model.dart';
import '../../controllers/home_controller.dart';

/// Find index of the last phase with is_completed == true (that one shows as "in progress").
int _lastCompletedIndex(List<ResidenceStatusPhaseModel> apiPhases) {
  for (int i = apiPhases.length - 1; i >= 0; i--) {
    if (apiPhases[i].isCompleted) return i;
  }
  return -1;
}

/// Map API phases to display models: last is_completed true → in-progress, previous completed → completed, is_completed false → upcoming (pending).
List<ConstructionPhaseModel> _apiPhasesToDisplayModels(
    List<ResidenceStatusPhaseModel> apiPhases) {
  final lastCompletedIdx = _lastCompletedIndex(apiPhases);
  final isIt = Get.locale?.languageCode == 'it';

  return apiPhases.asMap().entries.map((entry) {
    final index = entry.key;
    final p = entry.value;
    String status;
    if (!p.isCompleted) {
      status = 'pending'; // upcoming – grey
    } else if (index == lastCompletedIdx) {
      status = 'in-progress'; // last completed shows as in progress
    } else {
      status = 'completed';
    }

    final name = (isIt && p.phaseNameIt.isNotEmpty)
        ? p.phaseNameIt
        : p.phaseNameEn;
    DateTime? startDate;
    if (p.status?.statusDate != null && p.status!.statusDate!.isNotEmpty) {
      startDate = DateTime.tryParse(p.status!.statusDate!);
    }
    return ConstructionPhaseModel(
      id: p.phaseId.toString(),
      name: name,
      status: status,
      progress: status == 'completed' ? 100 : (status == 'in-progress' ? 50 : 0),
      startDate: startDate,
      endDate: null,
      description: p.status?.statusDescription,
      imageUrl: p.status?.image,
    );
  }).toList();
}

/// Month abbreviations (no intl locale data required).
const List<String> _monthAbbrEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _monthAbbrIt = [
  'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
  'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic',
];

/// Short date for timeline (e.g. "Jan 15", "15 Gen"). No intl locale init needed.
String _formatPhaseDate(DateTime date) {
  final isIt = Get.locale?.languageCode == 'it';
  final abbr = isIt ? _monthAbbrIt : _monthAbbrEn;
  final month = abbr[date.month - 1];
  return '${date.day} $month';
}

/// Sparkles: very subtle rotation, smooth and slow.
double _sparkleDegrees(double t) {
  if (t <= 0.0) return 0;
  if (t <= 0.25) return 10 * t * 4;
  if (t <= 0.5) return 10 - 20 * (t - 0.25) * 4;
  if (t <= 0.75) return -10 + 10 * (t - 0.5) * 4;
  return 0;
}

// Soft aqua for line and accents (Figma: not strong green / not Material teal).
const Color _timelineLineColor = AppColors.aquaGreen200;
const Color _circleAquaFill = AppColors.aquaGreen500;
const Color _circleAquaLight = AppColors.aquaGreen100;
const Color _circleGrey = AppColors.neutralLine200;
const double _circleDiameter = 44;
const double _lineWidth = 2;
const double _stepSpacing = 24;
const double _indicatorWidth = 44;
const double _timelineRowHeight = 132;

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
      iconData = Icons.construction;
      elevation = 2;
    } else {
      bgColor = _circleGrey;
      borderColor = _circleGrey;
      iconColor = AppColors.neutralInk400;
      iconData = Icons.schedule;
      elevation = 0;
    }

    final circle = Container(
      width: _circleDiameter,
      height: _circleDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        boxShadow: [
          if (elevation == 1)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          if (elevation == 2)
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Icon(iconData, color: iconColor, size: 19),
    );

    if (isFuture) {
      return Opacity(opacity: 0.85, child: circle);
    }
    return circle;
  }
}

/// Step card: rounded rect, padding 16–18, title left, date below, optional View document, status right.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.phase,
    this.onViewDocument,
  });

  final ConstructionPhaseModel phase;
  final VoidCallback? onViewDocument;

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
      statusLabel = 'upcoming'.tr;

    final dateStr = phase.startDate != null
        ? _formatPhaseDate(phase.startDate!)
        : '';

    // Figma: completed = no border, active = 2px aqua + slight glow, future = reduced opacity + grey.
    final cardColor = isFuture ? AppColors.neutralLine100 : AppColors.surfaceWhite;
    final borderWidth = isActive ? 2.0 : (isFuture ? 1.0 : 0.0);
    final borderColor = isFuture
        ? AppColors.neutralLine200
        : (isActive ? _circleAquaFill : Colors.transparent);
    final hasShadow = !isFuture;

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: isActive
                      ? _circleAquaFill.withOpacity(0.12)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isActive ? 8 : 4,
                  spreadRadius: isActive ? 0 : 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phase.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isFuture
                          ? AppColors.neutralInk400
                          : AppColors.neutralInk900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isFuture
                            ? AppColors.neutralInk400
                            : AppColors.neutralInk500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (onViewDocument != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onViewDocument,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: AppColors.aquaGreen500,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: AppColors.aquaGreen500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'view_document'.tr,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.aquaGreen500,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ], // close Column children
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCompleted || isActive)
                Container(
                  width: 7,
                  height: 7,
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

    if (isFuture) {
      return Opacity(opacity: 0.9, child: card);
    }
    return card;
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
    final controller = Get.find<HomeController>();

    return Obx(() {
      final apiPhases = controller.constructionPhasesFromApi;
      final loading = controller.constructionPhasesLoading.value;
      final displayPhases = _apiPhasesToDisplayModels(apiPhases);

      return Container(
            margin: const EdgeInsets.only(top: 32, left: 24, right: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.neutralLine100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
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
                            Expanded(
                              child: Text(
                                'construction_progress'.tr,
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.neutralInk900,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                        if (loading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.aquaGreen500,
                                ),
                              ),
                            ),
                          )
                        else if (displayPhases.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'no_construction_phases'.tr,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neutralInk500,
                              ),
                            ),
                          )
                        else
                          ...displayPhases.asMap().entries.map((entry) {
                            final index = entry.key;
                            final phase = entry.value;
                            final isFirst = index == 0;
                            final isLast =
                                index == displayPhases.length - 1;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLast ? 0 : _stepSpacing,
                              ),
                              child: SizedBox(
                                height: _timelineRowHeight,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _TimelineIndicator(
                                      isFirst: isFirst,
                                      isLast: isLast,
                                      status: phase.status,
                                      rowHeight: _timelineRowHeight,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _StepCard(
                                        phase: phase,
                                        onViewDocument:
                                            phase.imageUrl != null &&
                                                    phase.imageUrl!.isNotEmpty
                                                ? () => _openDocument(
                                                    phase.imageUrl!)
                                                : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
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
    });
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('ConstructionProgressSection _openDocument: $e');
    }
  }
}
