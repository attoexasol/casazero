class FeedItemModel {
  final String id;
  final String type; // 'maintenance', 'document', 'announcement'
  final String? priority; // 'low', 'medium', 'high'
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;

  FeedItemModel({
    required this.id,
    required this.type,
    this.priority,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
  });

  factory FeedItemModel.fromJson(Map<String, dynamic> json) {
    return FeedItemModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'announcement',
      priority: json['priority'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'priority': priority,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Create a copy with updated fields (for marking as read)
  FeedItemModel copyWith({
    String? id,
    String? type,
    String? priority,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return FeedItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}