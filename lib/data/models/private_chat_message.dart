import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: conversations/{id}/messages/{messageId}
class PrivateChatMessage {
  final String id;
  final int senderId;
  final String senderType;
  final String text;
  final DateTime createdAt;
  final bool read;

  const PrivateChatMessage({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.text,
    required this.createdAt,
    this.read = false,
  });

  bool get isFromResident => senderType == 'resident';
  bool get isFromAdmin => senderType == 'admin';

  factory PrivateChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAtRaw = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    }

    return PrivateChatMessage(
      id: doc.id,
      senderId: data['senderId'] is int
          ? data['senderId'] as int
          : int.tryParse(data['senderId']?.toString() ?? '') ?? 0,
      senderType: data['senderType']?.toString() ?? 'resident',
      text: data['text']?.toString() ?? '',
      createdAt: createdAt,
      read: data['read'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderType': senderType,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    };
  }
}
