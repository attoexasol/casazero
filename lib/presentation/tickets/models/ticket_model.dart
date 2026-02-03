/// Ticket model matching React Ticket interface.
class TicketModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String status; // 'open' | 'in-progress' | 'resolved'
  final String? priority;
  final String created;
  final String updated;
  final int? attachments;
  final int? updates;
  final String? assignedTo;
  final String? createdBy;

  const TicketModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.status,
    this.priority,
    required this.created,
    required this.updated,
    this.attachments,
    this.updates,
    this.assignedTo,
    this.createdBy,
  });
}
