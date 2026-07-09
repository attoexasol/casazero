// lib/presentation/home/views/sections/construction_progress_section.dart
// Construction Progress from API (status-with-phases). UI matches design: card radius 24,
// vertical aqua timeline, 42px circles, step cards with status; plus document view section.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  List<ResidenceStatusPhaseModel> apiPhases,
) {
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
      progress: status == 'completed'
          ? 100
          : (status == 'in-progress' ? 50 : 0),
      startDate: startDate,
      endDate: null,
      description: p.status?.statusDescription,
      imageUrl: p.status?.image,
    );
  }).toList();
}

/// Month abbreviations (no intl locale data required).
const List<String> _monthAbbrEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const List<String> _monthAbbrIt = [
  'Gen',
  'Feb',
  'Mar',
  'Apr',
  'Mag',
  'Giu',
  'Lug',
  'Ago',
  'Set',
  'Ott',
  'Nov',
  'Dic',
];

/// Short date for timeline (e.g. "Jan 15", "15 Gen"). No intl locale init needed.
String _formatPhaseDate(DateTime date) {
  final isIt = Get.locale?.languageCode == 'it';
  final abbr = isIt ? _monthAbbrIt : _monthAbbrEn;
  final month = abbr[date.month - 1];
  return '${date.day} $month';
}

// Timeline line + completed nodes: aqua (unchanged). In-progress uses brand sage below.
const Color _timelineLineColor = AppColors.aquaGreen200;
const Color _circleAquaFill = AppColors.aquaGreen700;
const Color _inProgressBrandDark = AppColors.brandSage800;
const Color _inProgressBrandLightBg = AppColors.brandSage100;
const Color _circleGrey = AppColors.neutralLine200;
double get _circleDiameter => 44.r;
double get _lineWidth => 2.w;
double get _stepSpacing => 24.h;
double get _indicatorWidth => 44.w;
double get _timelineRowHeight => 132.h;
double get _timelineRowHeightCompact => 92.h;

/// Loading skeleton: placeholder rows matching timeline layout (circle + card).
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < 3 ? _stepSpacing : 0),
          child: SizedBox(
            height: _timelineRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _indicatorWidth,
                  child: Center(
                    child: Container(
                      width: _circleDiameter,
                      height: _circleDiameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neutralLine100,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 17.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutralLine100,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 14.h,
                          width: 140.w,
                          decoration: BoxDecoration(
                            color: AppColors.neutralLine200,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          height: 10.h,
                          width: 60.w,
                          decoration: BoxDecoration(
                            color: AppColors.neutralLine200,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

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
            child: Container(
              color: status == 'in-progress'
                  ? _inProgressBrandDark
                  : _timelineLineColor,
            ),
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
      bgColor = _inProgressBrandLightBg;
      borderColor = _inProgressBrandDark;
      iconColor = _inProgressBrandDark;
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
      child: Icon(iconData, color: iconColor, size: 19.sp),
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
    this.phaseIndex,
    this.totalPhases,
    this.onViewDocument,
  });

  final ConstructionPhaseModel phase;
  final int? phaseIndex;
  final int? totalPhases;
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
    final cardColor = isFuture
        ? AppColors.neutralLine100
        : AppColors.surfaceWhite;
    final borderWidth = isActive ? 2.0 : (isFuture ? 1.0 : 0.0);
    final borderColor = isFuture
        ? AppColors.neutralLine200
        : (isActive ? _inProgressBrandDark : Colors.transparent);
    final hasShadow = !isFuture;

    final phaseSemantics = phaseIndex != null && totalPhases != null
        ? '${phase.name}. $statusLabel. ${phaseIndex!} of $totalPhases.'
        : '${phase.name}. $statusLabel.';

    final isCompact = isCompleted || isFuture;
    final cardPadding = EdgeInsets.symmetric(
      horizontal: 17.w,
      vertical: isCompact ? 10.h : 16.h,
    );

    final card = Semantics(
      label: phaseSemantics,
      child: Container(
        padding: cardPadding,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: isActive
                        ? _inProgressBrandDark.withOpacity(0.12)
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
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      phase.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                        color: isFuture
                            ? AppColors.neutralInk400
                            : AppColors.neutralInk900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateStr.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        dateStr,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isFuture
                              ? AppColors.neutralInk400
                              : AppColors.neutralInk500,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                    if (onViewDocument != null) ...[
                      SizedBox(height: 8.h),
                      Semantics(
                        button: true,
                        label: 'view_document'.tr,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onViewDocument,
                            borderRadius: BorderRadius.circular(8.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 10.h,
                                horizontal: 4.w,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 16.sp,
                                    color: AppColors.brandSage800,
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.open_in_new,
                                    size: 14.sp,
                                    color: AppColors.brandSage800,
                                  ),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      'view_document'.tr,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.brandSage800,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ], // close Column children
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCompleted || isActive)
                  Container(
                    width: 7.w,
                    height: 7.h,
                    margin: EdgeInsets.only(right: 6.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? _circleAquaFill
                          : _inProgressBrandDark,
                    ),
                  ),
                Flexible(
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isFuture
                          ? AppColors.neutralInk400
                          : (isActive
                              ? _inProgressBrandDark
                              : AppColors.neutralInk500),
                      fontSize: 12.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    extends State<ConstructionProgressSection> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final apiPhases = controller.constructionPhasesFromApi;
      final loading = controller.constructionPhasesLoading.value;
      final displayPhases = _apiPhasesToDisplayModels(apiPhases);

      return Container(
            margin: EdgeInsets.only(top: 32.h, left: 24.w, right: 24.w),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.neutralLine100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4.r,
                    spreadRadius: 0,
                    offset: Offset(0, 1.h),
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
                          width: 128.w,
                          height: 128.h,
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
                    padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
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
                                  fontSize: 20.sp,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'your_home_is_being_built'.tr,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutralInk500,
                            fontSize: 12.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 20.h),
                        if (loading)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: const _LoadingSkeleton(),
                          )
                        else if (displayPhases.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.h),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.construction_outlined,
                                    size: 40.sp,
                                    color: AppColors.neutralInk300,
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'no_construction_phases'.tr,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.neutralInk500,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...displayPhases.asMap().entries.map((entry) {
                            final index = entry.key;
                            final phase = entry.value;
                            final isFirst = index == 0;
                            final isLast = index == displayPhases.length - 1;
                            final rowHeight = phase.status == 'in-progress'
                                ? _timelineRowHeight
                                : _timelineRowHeightCompact;
                            return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : _stepSpacing,
                                  ),
                                  child: SizedBox(
                                    height: rowHeight,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _TimelineIndicator(
                                          isFirst: isFirst,
                                          isLast: isLast,
                                          status: phase.status,
                                          rowHeight: rowHeight,
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: _StepCard(
                                            phase: phase,
                                            phaseIndex: index + 1,
                                            totalPhases: displayPhases.length,
                                            onViewDocument:
                                                phase.imageUrl != null &&
                                                    phase.imageUrl!.isNotEmpty
                                                ? () => _openDocument(
                                                    phase.imageUrl!,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  duration: 280.ms,
                                  curve: Curves.easeOut,
                                  delay: (index * 50).ms,
                                )
                                .slideY(
                                  begin: 0.04,
                                  end: 0,
                                  duration: 280.ms,
                                  curve: Curves.easeOut,
                                  delay: (index * 50).ms,
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
