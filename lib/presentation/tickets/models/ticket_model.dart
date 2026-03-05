import 'package:intl/intl.dart';

/// Ticket model matching the API response from /my-support-tickets.
class TicketModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String status;
  final String? priority;
  final String created;
  final String updated;
  final int? attachments;
  final int? updates;
  final String? assignedTo;
  final String? createdBy;
  final String? imageUrl;
  final int? issueTypeId;

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
    this.imageUrl,
    this.issueTypeId,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId?.toString() ?? '0';

    final rawStatus = (json['status']?.toString() ?? 'open').toLowerCase();
    final status = _normalizeStatus(rawStatus);

    String createdStr = '';
    if (json['created_at'] != null) {
      createdStr = _formatDate(json['created_at'].toString());
    }

    String updatedStr = '';
    if (json['updated_at'] != null) {
      updatedStr = _formatDate(json['updated_at'].toString());
    }

    final image = json['image']?.toString();
    final hasImage = image != null && image.isNotEmpty && image != 'null';

    final user = json['user'];
    final userName = user is Map ? user['user_name']?.toString() : null;

    final rawIssueTypeId = json['issue_type_id'];
    final issueTypeId = rawIssueTypeId is int
        ? rawIssueTypeId
        : int.tryParse(rawIssueTypeId?.toString() ?? '');

    return TicketModel(
      id: id,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: status,
      priority: json['priority']?.toString(),
      created: createdStr,
      updated: updatedStr,
      attachments: hasImage ? 1 : 0,
      updates: null,
      assignedTo: null,
      createdBy: userName,
      imageUrl: hasImage ? image : null,
      issueTypeId: issueTypeId,
    );
  }

  static String _normalizeStatus(String raw) {
    switch (raw) {
      case 'in_progress':
        return 'in-progress';
      case 'closed':
        return 'resolved';
      case 'pending':
      case 'open':
      case 'in-progress':
      case 'resolved':
        return raw;
      default:
        return raw;
    }
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
