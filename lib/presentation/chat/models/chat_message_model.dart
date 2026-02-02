import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat message model matching Firestore structure.
/// Supports text and image messages.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'admin' | 'resident' | 'user'
  final String type; // 'chat' | 'announcement' | 'image'
  final String? text;
  final String? imageUrl;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.type,
    this.text,
    this.imageUrl,
    required this.timestamp,
  });

  /// Display name (alias for senderName)
  String get sender => senderName;

  /// Display content: text or placeholder for image
  String get content {
    if (text != null && text!.isNotEmpty) return text!;
    if (type == 'image' && imageUrl != null) return '[Image]';
    return '';
  }

  /// Create from Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdAt = data['createdAt'];
    DateTime timestamp = DateTime.now();
    if (createdAt != null) {
      if (createdAt is Timestamp) {
        timestamp = createdAt.toDate();
      } else if (createdAt is DateTime) {
        timestamp = createdAt;
      }
    }
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'Unknown',
      senderRole: data['senderRole']?.toString() ?? 'user',
      type: data['type']?.toString() ?? 'chat',
      text: data['text']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      timestamp: timestamp,
    );
  }

  /// Convert to Firestore map for writing
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'type': type,
      if (text != null && text!.isNotEmpty) 'text': text,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(timestamp),
    };
  }
}
