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
  final String? unitName;

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
    this.unitName,
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
      residenceId: parseResidenceId(json['residence_id']),
      residenceStatus: _parseResidenceStatus(json['residence_status']),
      unitName: _optionalNonEmptyString(json['unit_name']),
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
      'unit_name': unitName,
    };
  }

  /// Parses Laravel/API role strings (e.g. resident, administrator).
  static Role parseRoleFromApi(dynamic raw) {
    if (raw is Map) {
      raw = raw['name'] ?? raw['slug'] ?? raw['role'] ?? raw['type'];
    }
    final roleStr = raw?.toString().toLowerCase().trim() ?? '';
    switch (roleStr) {
      case 'admin':
      case 'administrator':
      case 'amministratore':
      case 'super_admin':
      case 'superadmin':
      case 'building_admin':
        return Role.admin;
      case 'manager':
        return Role.manager;
      case 'client':
      case 'resident':
      case 'user':
        return Role.client;
      default:
        return Role.client;
    }
  }

  static Role _parseRole(dynamic raw) => parseRoleFromApi(raw);

  /// Parses raw residence ID which might be an int (139), a string ("139"),
  /// a List ([139]), a bracketed string ("[139]"), or JSON array string ("[\"139\"]").
  /// Returns a clean ID string (e.g. "139") without brackets or quotes.
  static String? parseResidenceId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw.toString();
    if (raw is List) {
      if (raw.isEmpty) return null;
      return parseResidenceId(raw.first);
    }
    final str = raw.toString().trim();
    if (str.isEmpty || str == 'null' || str == '[]') return null;
    final cleaned = str.replaceAll(RegExp(r'[\[\]"\'\s]'), '');
    if (cleaned.isEmpty) return null;
    final first = cleaned.split(',').first.trim();
    return first.isNotEmpty ? first : null;
  }

  /// Parses raw residence ID into an integer without any brackets or formatting artifacts.
  static int? parseResidenceIdAsInt(dynamic raw) {
    if (raw is int) return raw;
    final str = parseResidenceId(raw);
    if (str == null) return null;
    return int.tryParse(str);
  }

  static String? _optionalNonEmptyString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
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

  // Helper method to parse residence status (used in fromJson)
  static ResidenceStatus? _parseResidenceStatus(String? statusStr) =>
      parseResidenceStatus(statusStr);

  /// Parse API residence_status string to enum. Use when syncing from residence API.
  static ResidenceStatus? parseResidenceStatus(String? statusStr) {
    if (statusStr == null || statusStr.toString().trim().isEmpty) return null;
    final normalized = statusStr
        .toString()
        .toLowerCase()
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    if (normalized == 'completed') return ResidenceStatus.completed;
    if (normalized == 'pending') return ResidenceStatus.pending;
    if (normalized.contains('under construction') ||
        normalized.contains('in progress') ||
        normalized.contains('work in progress')) {
      return ResidenceStatus.underConstruction;
    }
    return null;
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
    String? unitName,
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
      unitName: unitName ?? this.unitName,
    );
  }
}