// presentation/maintenance/views/maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/core/widgets/floating_bottom_nav_bar.dart';
import 'package:casazero/core/widgets/tablet_centered_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'sections/maintenance_filter_bar.dart';
import 'sections/maintenance_task_card.dart';
import 'sections/maintenance_empty_state.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceScreen extends StatefulWidget {
  final String role; // 'client', 'admin', 'super-admin'
  final VoidCallback onAskAI;

  const MaintenanceScreen({
    super.key,
    required this.role,
    required this.onAskAI,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  String _activeFilter = 'all';

  late AnimationController _fabController;

  late final MaintenanceController _controller;

  @override
  void initState() {
    super.initState();
    // Ensure controller is initialized, reuse if exists
    if (!Get.isRegistered<MaintenanceController>()) {
      _controller = Get.put(MaintenanceController());
    } else {
      _controller = Get.find<MaintenanceController>();
    }
    // Ensure "All" filter is selected by default
    _activeFilter = 'all';
    _controller.setSelectedCategoryId(null); // null = "All"
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // Removed _getFilteredTasks() - filtering now handled in controller
  // Use _controller.filteredTasks instead

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            SizedBox(height: 12.h),
            ClipRect(
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                height: 48.h,
                child: Obx(
                  () => MaintenanceFilterBar(
                    activeFilter: _activeFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _activeFilter = filter;
                      });
                    },
                    apiCategories: _controller.categories,
                    categoryCounts: _controller.categoryTaskCounts,
                    isLoading: _controller.isLoadingCategories.value ||
                        (_controller.isLoadingTasks.value &&
                            _controller.tasks.isEmpty),
                    totalTaskCount: _controller.totalTaskCount.value,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// TASKS LIST
            Expanded(
              child: Obx(() {
                  // Show error state if there's an error
                  if (_controller.hasError.value &&
                      _controller.tasks.isEmpty &&
                      !_controller.isLoadingTasks.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Tasks',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.w),
                            child: Text(
                              _controller.errorMessage.value.isNotEmpty
                                  ? _controller.errorMessage.value
                                  : 'Failed to load maintenance tasks. Please try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => _controller.refreshData(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandSage500,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_controller.isLoadingTasks.value &&
                      _controller.tasks.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandSage500,
                      ),
                    );
                  }

                  // Use filtered tasks from controller (filtering logic is in controller)
                  final filteredTasks = _controller.filteredTasks.toList();

                  if (filteredTasks.isEmpty) {
                    return MaintenanceEmptyState(
                      title: 'No Maintenance Tasks',
                      description:
                          'Create your first maintenance task to get started',
                    );
                  }

                  return TabletCenteredLayout(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: RefreshIndicator(
                          onRefresh: () => _controller.refreshData(),
                          color: AppColors.brandSage500,
                          child: ListView.builder(
                            padding:
                                FloatingBottomNavBar.screenPadding(context),
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];
                              return MaintenanceTaskCard(
                                    task: task,
                                    onAskAI: widget.onAskAI,
                                  )
                                  .animate()
                                  .fadeIn(
                                      delay: Duration(milliseconds: 50 * index))
                                  .slideY(begin: 0.1, end: 0);
                            },
                          ),
                        ),
                      ),
                  );
                }),
            ),
          ],
        ),

          // Floating Action Button
          // Positioned(
          //   right: 16,
          //   bottom: 16,
          //   child: ScaleTransition(
          //     scale: CurvedAnimation(
          //       parent: _fabController,
          //       curve: Curves.elasticOut,
          //     ),
          //     child: FloatingActionButton(
          //       onPressed: _showCreateDialog,
          //       backgroundColor: AppColors.brandSage600,
          //       elevation: 4,
          //       child: const Icon(
          //         Icons.add_rounded,
          //         color: AppColors.surfaceWhite,
          //         size: 28,
          //       ),
          //     ),
          //   ),
          // ),

          /// FLOATING ACTION BUTTON
          // if (canCreateTasks)
          //   Positioned(
          //     bottom: 20,
          //     right: 20,
          //     child:
          //         FloatingActionButton(
          //             backgroundColor: const Color(0xFF4CAF47),
          //             onPressed: _showCreateDialog,
          //             child: const Icon(Icons.add, size: 26, color: Colors.white),
          //           ).animate()
          //           ..scale(
          //             begin: const Offset(0.5, 0.5),
          //             end: const Offset(1, 1),
          //           ).fadeIn(),
          //   ),

          //   // Add Maintenance Task Dialog
          //   if (_isCreateDialogVisible)
          //     AddMaintenanceTaskDialog(
          //       onClose: () {
          //     setState(() {
          //           _isCreateDialogVisible = false;
          //     });
          //   },
          //     ),
        ],
    );
  }
}
