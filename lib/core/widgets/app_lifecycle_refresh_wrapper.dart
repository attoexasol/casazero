// core/widgets/app_lifecycle_refresh_wrapper.dart
// Refreshes notifications and documents when app resumes from background.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/home/controllers/home_controller.dart';
import '../../presentation/documents/controllers/documents_controller.dart';

/// Wraps the main scaffold and triggers data refresh when app lifecycle becomes [AppLifecycleState.resumed].
class AppLifecycleRefreshWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleRefreshWrapper({super.key, required this.child});

  @override
  State<AppLifecycleRefreshWrapper> createState() =>
      _AppLifecycleRefreshWrapperState();
}

class _AppLifecycleRefreshWrapperState extends State<AppLifecycleRefreshWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResumed();
    }
  }

  void _onResumed() {
    try {
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        home.fetchNotifications();
        home.fetchUnreadCount();
      }
      if (Get.isRegistered<DocumentsController>()) {
        Get.find<DocumentsController>().fetchDocuments();
      }
    } catch (e) {
      // Controllers may not be ready yet
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
