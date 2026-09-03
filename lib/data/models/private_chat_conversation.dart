import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/// Firestore document: conversations/{conversationId}
class PrivateChatConversation {
  final String id;
  final int adminId;
  final int residentId;
  final String adminName;
  final String residentName;
  final int residenceId;
  final String residenceName;
  final List<int> participants;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadAdmin;
  final int unreadResident;
  final String? adminProfileImage;

  const PrivateChatConversation({
    required this.id,
    required this.adminId,
    required this.residentId,
    required this.adminName,
    required this.residentName,
    required this.residenceId,
    required this.residenceName,
    required this.participants,
    this.createdAt,
    this.updatedAt,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadAdmin = 0,
    this.unreadResident = 0,
    this.adminProfileImage,
  });

  static String buildId({required int adminId, required int residentId}) {
    return 'admin_${adminId}_user_$residentId';
  }

  int get unreadForResident => unreadResident;

  factory PrivateChatConversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PrivateChatConversation(
      id: doc.id,
      adminId: _readInt(data['adminId']),
      residentId: _readInt(data['residentId']),
      adminName: data['adminName']?.toString() ?? '',
      residentName: data['residentName']?.toString() ?? '',
      residenceId: _readInt(data['residenceId']),
      residenceName: data['residenceName']?.toString() ?? '',
      participants: _readIntList(data['participants']),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastMessageAt: _readDate(data['lastMessageAt']),
      unreadAdmin: _readInt(data['unreadAdmin']),
      unreadResident: _readInt(data['unreadResident']),
      adminProfileImage: data['adminProfileImage']?.toString(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'adminId': adminId,
      'residentId': residentId,
      'adminName': adminName,
      'residentName': residentName,
      'residenceId': residenceId,
      'residenceName': residenceName,
      'participants': participants,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadAdmin': 0,
      'unreadResident': 0,
      if (adminProfileImage != null && adminProfileImage!.isNotEmpty)
        'adminProfileImage': adminProfileImage,
    };
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return UserModel.parseResidenceIdAsInt(value) ?? 0;
  }

  static List<int> _readIntList(dynamic value) {
    if (value is! List) return const [];
    return value.map(_readInt).toList();
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
