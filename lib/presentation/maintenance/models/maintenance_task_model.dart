// presentation/maintenance/models/maintenance_task_model.dart
// Maintenance Task Models

enum MaintenancePriority { facoltative, obbligatorie, condominiali, personal }

enum MaintenanceStatus { pending, inProgress, completed, overdue }

class MaintenanceTask {
  final String id;
  final String title;
  final String category;
  final String description;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final String frequency;
  final String? nextDue;
  final List<TaskAttachment>? attachments;
  final List<TaskContact>? contacts;
  final String? lastCompleted;

  MaintenanceTask({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    required this.frequency,
    this.nextDue,
    this.attachments,
    this.contacts,
    this.lastCompleted,
  });
}

class TaskAttachment {
  final String name;
  final String type;
  final String url;

  TaskAttachment({
    required this.name,
    required this.type,
    required this.url,
  });
}

class TaskContact {
  final String name;
  final String role;
  final String? phone;
  final String? email;

  TaskContact({
    required this.name,
    required this.role,
    this.phone,
    this.email,
  });
}



