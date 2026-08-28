import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/app_colors.dart';
import 'shimmer_loading.dart';

class FilterBarItem {
  final String id;
  final String label;
  final int count;

  const FilterBarItem({
    required this.id,
    required this.label,
    required this.count,
  });
}

/// Shared horizontal category filter bar used on Documents and Maintenance screens.
class CategoryFilterBar extends StatelessWidget {
  final String activeId;
  final ValueChanged<String> onSelected;
  final List<FilterBarItem> items;
  final bool isLoading;
  final Color Function(String id)? colorForId;
  final bool showActiveShadow;
  final bool useOutlineActiveStyle;

  const CategoryFilterBar({
    super.key,
    required this.activeId,
    required this.onSelected,
    required this.items,
    this.isLoading = false,
    this.colorForId,
    this.showActiveShadow = true,
    this.useOutlineActiveStyle = false,
  });

  Color _accentColor(String id) =>
      colorForId?.call(id) ?? AppColors.brandSage600;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxContentWidth = screenWidth >= 600 ? 600.0 : double.infinity;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            height: 48.h,
            child: isLoading || items.isEmpty
                ? _buildLoadingList()
                : ListView.separated(
                    clipBehavior: Clip.hardEdge,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (_, index) => SizedBox(
                      height: 48.h,
                      child: Align(
                        alignment: Alignment.center,
                        child: _buildChip(
                          items[index],
                          _accentColor(items[index].id),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, __) => SizedBox(width: 8.w),
      itemBuilder: (_, index) {
        return SizedBox(
          height: 48.h,
          child: Align(
            alignment: Alignment.center,
            child: ShimmerLoading(
              width: index == 0 ? 72.w : 96.w,
              height: 32.h,
              borderRadius: 30.r,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(FilterBarItem item, Color accentColor) {
    final isActive = item.id == activeId;
    final useOutline = useOutlineActiveStyle && isActive;

    final decoration = BoxDecoration(
      color: useOutline
          ? Colors.white
          : (isActive ? accentColor : Colors.white),
      borderRadius: BorderRadius.circular(30.r),
      border: Border.all(
        color: useOutline
            ? accentColor
            : (isActive ? Colors.transparent : Colors.grey.shade300),
        width: useOutline ? 1.5 : 1,
      ),
      boxShadow: isActive && showActiveShadow && !useOutlineActiveStyle
          ? [
              BoxShadow(
                color: accentColor.withValues(alpha: .25),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ]
          : const [],
    );

    final chipBody = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 180.w),
          child: Text(
            item.label,
            style: TextStyle(
              color: useOutline
                  ? accentColor
                  : (isActive ? Colors.white : Colors.black87),
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 6.w),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: 2.h,
          ),
          decoration: BoxDecoration(
            color: useOutline
                ? accentColor.withValues(alpha: 0.12)
                : (isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(50.r),
          ),
          child: Text(
            '${item.count}',
            style: TextStyle(
              color: useOutline
                  ? accentColor
                  : (isActive ? Colors.white : Colors.black87),
              fontSize: 12.sp,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => onSelected(item.id),
      child: showActiveShadow
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              decoration: decoration,
              child: chipBody,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                decoration: decoration,
                child: chipBody,
              ),
            ),
    );
  }
}
