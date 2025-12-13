// presentation/maintenance/views/maintenance_screen.dart
import 'package:casazero/app/theme/app_colors.dart';
import 'package:casazero/core/utils/permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'sections/maintenance_filter_bar.dart';
import 'sections/maintenance_task_card.dart';
import 'sections/maintenance_empty_state.dart';
import 'sections/add_maintenance_task_dialog.dart';
import '../controllers/maintenance_controller.dart';
import '../models/maintenance_task_model.dart';

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
  bool _isCreateDialogVisible = false;

  late AnimationController _fabController;

  final MaintenanceController _controller = Get.put(MaintenanceController());

  @override
  void initState() {
    super.initState();
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

  List<MaintenanceTask> _getFilteredTasks() {
    final allTasks = _controller.tasks.toList();
    if (_activeFilter == 'all') return allTasks;

    return allTasks.where((task) {
      switch (_activeFilter) {
        case 'personal':
          return task.priority == MaintenancePriority.personal;
        case 'facoltative':
          return task.priority == MaintenancePriority.facoltative;
        case 'obbligatorie':
          return task.priority == MaintenancePriority.obbligatorie;
        case 'condominiali':
          return task.priority == MaintenancePriority.condominiali;
        case 'pending':
          return task.status == MaintenanceStatus.pending;
        case 'overdue':
          return task.status == MaintenanceStatus.overdue;
        default:
          return true;
      }
    }).toList();
  }

  void _showCreateDialog() {
    setState(() {
      _isCreateDialogVisible = true;
    });
  }


  Role _getRoleFromString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'manager':
        return Role.manager;
      case 'client':
      default:
        return Role.client;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleEnum = _getRoleFromString(widget.role);
    final permissions = Permissions.fromRole(roleEnum);
    // Allow all users to create personal maintenance tasks
    final canCreateTasks = true; // All users can create personal maintenance tasks
    
    return Scaffold(
      backgroundColor: AppColors.surfaceWarm50,
      body: Stack(
        children: [
          Column(
            children: [
              // Filter Bar
              MaintenanceFilterBar(
                activeFilter: _activeFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _activeFilter = filter;
                  });
                },
              ),

              // Tasks List
              Expanded(
                child: Obx(() {
                  if (_controller.isLoadingTasks.value &&
                      _controller.tasks.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandSage500,
                      ),
                    );
                  }

                  final filteredTasks = _getFilteredTasks();

                  if (filteredTasks.isEmpty) {
                    return MaintenanceEmptyState(
                      title: 'No Maintenance Tasks',
                      description: 'Create your first maintenance task to get started',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => _controller.refreshData(),
                    color: AppColors.brandSage500,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return MaintenanceTaskCard(
                          task: task,
                          onAskAI: widget.onAskAI,
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 50 * index))
                            .slideY(begin: 0.1, end: 0);
                      },
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
        if (canCreateTasks)
          Positioned(
            bottom: 20,
            right: 20,
            child:
                FloatingActionButton(
                    backgroundColor: const Color(0xFF4CAF47),
                    onPressed: _showCreateDialog,
                    child: const Icon(Icons.add, size: 26, color: Colors.white),
                  ).animate()
                  ..scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                  ).fadeIn(),
          ),

          // Add Maintenance Task Dialog
          if (_isCreateDialogVisible)
            AddMaintenanceTaskDialog(
              onClose: () {
                setState(() {
                  _isCreateDialogVisible = false;
                });
              },
            ),
        ],
      ),
    );
  }
}


