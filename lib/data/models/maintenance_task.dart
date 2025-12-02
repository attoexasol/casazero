// lib/features/maintenance/models/maintenance_task.dart

enum MaintenancePriority {
  facoltative,
  obbligatorie,
  condominiali,
  personal,
}

enum MaintenanceStatus {
  pending,
  inProgress,
  completed,
  overdue,
}

class MaintenanceAttachment {
  final String name;
  final String type;
  final String url;

  MaintenanceAttachment({
    required this.name,
    required this.type,
    required this.url,
  });
}

class MaintenanceContact {
  final String name;
  final String role;
  final String? phone;
  final String? email;

  MaintenanceContact({
    required this.name,
    required this.role,
    this.phone,
    this.email,
  });
}

class MaintenanceTask {
  final String id;
  final String title;
  final String category;
  final String description;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final String frequency;
  final String? nextDue;
  final String? lastCompleted;
  final List<MaintenanceAttachment>? attachments;
  final List<MaintenanceContact>? contacts;

  MaintenanceTask({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    required this.frequency,
    this.nextDue,
    this.lastCompleted,
    this.attachments,
    this.contacts,
  });
}
