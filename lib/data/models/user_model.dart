import '../../core/utils/permissions.dart';

enum ResidenceStatus {
  completed,
  underConstruction,
  pending,
}
class UserModel {
  final int id;
  final String userName;
  final String email;
  final String phone;
  final Role role;
  final String language;
  final String? profileImage;
  final int userStatus;
  final String twoFaMethod;
  final DateTime registrationDate;
  final bool isDocumentNotify;
  final bool isMaintenanceNotify;
  final bool isChatNotify;
  final bool isSupportTicketNotify;
  final bool isPasswordSetByAdmin;

  // Additional fields for app logic
  final String? residenceId;
  final ResidenceStatus? residenceStatus;

  UserModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.phone,
    required this.role,
    required this.language,
    this.profileImage,
    required this.userStatus,
    required this.twoFaMethod,
    required this.registrationDate,
    required this.isDocumentNotify,
    required this.isMaintenanceNotify,
    required this.isChatNotify,
    required this.isSupportTicketNotify,
    required this.isPasswordSetByAdmin,
    this.residenceId,
    this.residenceStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: _parseRole(json['role']),
      language: json['language'] ?? 'en',
      profileImage: json['profile_image'],
      userStatus: json['user_status'] ?? 0,
      twoFaMethod: json['two_fa_method'] ?? 'email',
      registrationDate: json['registration_date'] != null
          ? DateTime.parse(json['registration_date'])
          : DateTime.now(),
      isDocumentNotify: _parseBool(json['is_document_notify']),
      isMaintenanceNotify: _parseBool(json['is_maintenance_notify']),
      isChatNotify: _parseBool(json['is_chat_notify']),
      isSupportTicketNotify: _parseBool(json['is_support_ticket_notify']),
      isPasswordSetByAdmin: _parseBool(json['is_password_set_by_admin']),
      residenceId: json['residence_id']?.toString(),
      residenceStatus: _parseResidenceStatus(json['residence_status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'language': language,
      'profile_image': profileImage,
      'user_status': userStatus,
      'two_fa_method': twoFaMethod,
      'registration_date': registrationDate.toIso8601String(),
      'is_document_notify': isDocumentNotify.toString(),
      'is_maintenance_notify': isMaintenanceNotify.toString(),
      'is_chat_notify': isChatNotify.toString(),
      'is_support_ticket_notify': isSupportTicketNotify.toString(),
      'is_password_set_by_admin': isPasswordSetByAdmin.toString(),
      'residence_id': residenceId,
      'residence_status': residenceStatus?.name,
    };
  }

  // Helper method to parse role
  static Role _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'manager':
        return Role.manager;
      case 'client':
      default:
        return Role.client;
    }
  }

  // Helper method to parse boolean from string
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  // Helper method to parse residence status
  static ResidenceStatus? _parseResidenceStatus(String? statusStr) {
    switch (statusStr?.toLowerCase()) {
      case 'completed':
        return ResidenceStatus.completed;
      case 'under-construction':
      case 'under_construction':
        return ResidenceStatus.underConstruction;
      default:
        return null;
    }
  }

  // Computed properties
  bool get isActive => userStatus == 1;

  bool get is2FAEnabled => twoFaMethod.isNotEmpty && twoFaMethod != 'none';

  bool get isFirstLogin => isPasswordSetByAdmin;

  String get firstName => userName.split(' ').first;

  String get fullName => userName;

  // Copy with method for updating user data
  UserModel copyWith({
    int? id,
    String? userName,
    String? email,
    String? phone,
    Role? role,
    String? language,
    String? profileImage,
    int? userStatus,
    String? twoFaMethod,
    DateTime? registrationDate,
    bool? isDocumentNotify,
    bool? isMaintenanceNotify,
    bool? isChatNotify,
    bool? isSupportTicketNotify,
    bool? isPasswordSetByAdmin,
    String? residenceId,
    ResidenceStatus? residenceStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      language: language ?? this.language,
      profileImage: profileImage ?? this.profileImage,
      userStatus: userStatus ?? this.userStatus,
      twoFaMethod: twoFaMethod ?? this.twoFaMethod,
      registrationDate: registrationDate ?? this.registrationDate,
      isDocumentNotify: isDocumentNotify ?? this.isDocumentNotify,
      isMaintenanceNotify: isMaintenanceNotify ?? this.isMaintenanceNotify,
      isChatNotify: isChatNotify ?? this.isChatNotify,
      isSupportTicketNotify: isSupportTicketNotify ?? this.isSupportTicketNotify,
      isPasswordSetByAdmin: isPasswordSetByAdmin ?? this.isPasswordSetByAdmin,
      residenceId: residenceId ?? this.residenceId,
      residenceStatus: residenceStatus ?? this.residenceStatus,
    );
  }
}