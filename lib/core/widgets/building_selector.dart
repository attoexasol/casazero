import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/building_model.dart';

enum UserRole { admin, superAdmin, resident }

class BuildingSelector extends StatefulWidget {
  final UserRole role;
  final BuildingModel currentBuilding;
  final List<BuildingModel> buildings;
  final ValueChanged<String>? onBuildingChange;

  const BuildingSelector({
    super.key,
    required this.role,
    required this.currentBuilding,
    this.buildings = const [],
    this.onBuildingChange,
  });

  @override
  State<BuildingSelector> createState() => _BuildingSelectorState();
}

class _BuildingSelectorState extends State<BuildingSelector> {
  late String selectedBuilding;

  @override
  void initState() {
    super.initState();
    selectedBuilding = widget.currentBuilding.id;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == UserRole.superAdmin && widget.buildings.isNotEmpty) {
      return _buildSuperAdminSelector();
    }

    if (widget.role == UserRole.admin) {
      return _buildAdminView();
    }

    return _buildResidentView();
  }

  // -----------------------------------------------------------------------
  // SUPER ADMIN — CAN SWITCH BUILDINGS
  // -----------------------------------------------------------------------
  Widget _buildSuperAdminSelector() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      color: AppColors.neutralInk900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.building, size: 16.sp, color: Colors.white),
              SizedBox(width: 6.w),
              Text(
                "Building Scope",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(width: 6.w),
              _badge("Super Admin"),
            ],
          ),
          SizedBox(height: 10.h),

          // Dropdown
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: AppColors.neutralInk900,
                value: selectedBuilding,
                icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                items: widget.buildings.map((b) {
                  return DropdownMenuItem(
                    value: b.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          b.address,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedBuilding = value);
                    widget.onBuildingChange?.call(value);
                  }
                },
              ),
            ),
          ),

          SizedBox(height: 8.h),
          Text(
            "${widget.currentBuilding.units} units · ${widget.currentBuilding.residents} residents",
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // ADMIN — SEES ONLY CURRENT BUILDING
  // -----------------------------------------------------------------------
  Widget _buildAdminView() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      color: AppColors.brandSage600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.building, size: 16.sp, color: Colors.white),
              SizedBox(width: 6.w),
              Text(
                "Managing Building",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              SizedBox(width: 6.w),
              _badge("Admin"),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            widget.currentBuilding.name,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            widget.currentBuilding.address,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "${widget.currentBuilding.units} units · ${widget.currentBuilding.residents} residents",
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // RESIDENT — SIMPLE VIEW
  // -----------------------------------------------------------------------
  Widget _buildResidentView() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      color: AppColors.surfaceWarm50,
      child: Row(
        children: [
          Icon(
            LucideIcons.building,
            size: 16.sp,
            color: AppColors.neutralInk500,
          ),
          SizedBox(width: 6.w),
          Text(
            widget.currentBuilding.name,
            style: TextStyle(fontSize: 14.sp, color: AppColors.neutralInk700),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // BADGE COMPONENT
  // -----------------------------------------------------------------------
  Widget _badge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
