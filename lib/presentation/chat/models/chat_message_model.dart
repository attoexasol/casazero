import 'package:cloud_firestore/cloud_firestore.dart';

/// Text-only chat message. Firestore: groups/{groupId}/messages/{messageId}
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderRole; // "user" | "admin"
  final String senderName;
  /// Profile image URL from API (optional; when missing, avatar shows initials).
  final String? senderProfileImage;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    this.senderProfileImage,
    required this.createdAt,
  });

  String get sender => senderName;

  String get content => text;

  DateTime get timestamp => createdAt;

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdAtRaw = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdAtRaw != null) {
      if (createdAtRaw is Timestamp) {
        createdAt = createdAtRaw.toDate();
      } else if (createdAtRaw is DateTime) {
        createdAt = createdAtRaw;
      }
    }
    final role = data['senderRole']?.toString().toLowerCase() ?? 'user';
    final senderRole = role == 'admin' ? 'admin' : 'user';
    final profileImage = data['senderProfileImage']?.toString();
    return ChatMessage(
      id: doc.id,
      text: data['text']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderRole: senderRole,
      senderName: data['senderName']?.toString() ?? 'Unknown',
      senderProfileImage: profileImage != null && profileImage.isNotEmpty
          ? profileImage
          : null,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'text': text,
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (senderProfileImage != null && senderProfileImage!.isNotEmpty) {
      map['senderProfileImage'] = senderProfileImage;
    }
    return map;
  }
}
