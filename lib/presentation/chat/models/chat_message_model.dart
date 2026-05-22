import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/permissions.dart';

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

  bool get isAdminSender => senderRole == 'admin';

  bool get isManagerSender => senderRole == 'manager';

  bool get showStaffBadge => isAdminSender || isManagerSender;

  /// Firestore `senderRole` for the logged-in app user when sending a message.
  static String senderRoleForUser(Role role) {
    switch (role) {
      case Role.admin:
        return 'admin';
      case Role.manager:
        return 'manager';
      case Role.client:
        return 'user';
    }
  }

  /// Normalizes API/Firestore role strings to `admin`, `manager`, or `user`.
  static String normalizeSenderRole(dynamic raw) {
    if (raw == true || raw == 1 || raw == '1' || raw == 'true') {
      return 'admin';
    }
    if (raw is Map) {
      return normalizeSenderRole(
        raw['name'] ?? raw['slug'] ?? raw['role'] ?? raw['type'],
      );
    }
    final role = raw?.toString().toLowerCase().trim() ?? '';
    if (role.isEmpty) return 'user';
    if (role == 'admin' ||
        role == 'administrator' ||
        role == 'amministratore' ||
        role == 'super_admin' ||
        role == 'superadmin' ||
        role == 'building_admin') {
      return 'admin';
    }
    if (role == 'manager') return 'manager';
    return 'user';
  }

  static bool readIsAdminFlag(Map<String, dynamic> data) {
    final v = data['is_admin'] ?? data['isAdmin'];
    return v == true || v == 1 || v == '1' || v == 'true';
  }

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
    var senderRole = normalizeSenderRole(
      data['senderRole'] ??
          data['sender_role'] ??
          data['role'] ??
          data['user_role'] ??
          data['userRole'],
    );
    if (senderRole == 'user' && readIsAdminFlag(data)) {
      senderRole = 'admin';
    }
    final profileImage = data['senderProfileImage']?.toString() ??
        data['sender_profile_image']?.toString();
    return ChatMessage(
      id: doc.id,
      text: data['text']?.toString() ?? '',
      senderId: (data['senderId'] ?? data['sender_id'])?.toString() ?? '',
      senderRole: senderRole,
      senderName: (data['senderName'] ?? data['sender_name'])?.toString() ??
          'Unknown',
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
