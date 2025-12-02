// data/models/trusted_device_model.dart

class TrustedDeviceModel {
  final int id;
  final int userId;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String? lastIp;
  final String? userAgent;
  final DateTime? lastLoginAt;
  final DateTime? trustedUntil;
  final double? lat;
  final double? lng;
  final bool isRevoked;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrustedDeviceModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.lastIp,
    this.userAgent,
    this.lastLoginAt,
    this.trustedUntil,
    this.lat,
    this.lng,
    required this.isRevoked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrustedDeviceModel.fromJson(Map<String, dynamic> json) {
    return TrustedDeviceModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? 'Unknown Device',
      platform: json['platform'] ?? 'unknown',
      lastIp: json['last_ip'],
      userAgent: json['user_agent'],
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
      trustedUntil: json['trusted_until'] != null
          ? DateTime.parse(json['trusted_until'])
          : null,
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      isRevoked: json['is_revoked'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'last_ip': lastIp,
      'user_agent': userAgent,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'trusted_until': trustedUntil?.toIso8601String(),
      'lat': lat?.toString(),
      'lng': lng?.toString(),
      'is_revoked': isRevoked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // Helper methods
  bool get hasLocation => lat != null && lng != null;

  String get platformIcon {
    switch (platform.toLowerCase()) {
      case 'android':
        return '🤖';
      case 'ios':
        return '🍎';
      default:
        return '📱';
    }
  }

  String get platformName {
    switch (platform.toLowerCase()) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      default:
        return 'Unknown';
    }
  }

  bool get isActive => !isRevoked;

  bool get isTrustedValid {
    if (trustedUntil == null) return true;
    return DateTime.now().isBefore(trustedUntil!);
  }

  Duration? get timeSinceLastLogin {
    if (lastLoginAt == null) return null;
    return DateTime.now().difference(lastLoginAt!);
  }

  TrustedDeviceModel copyWith({
    int? id,
    int? userId,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? lastIp,
    String? userAgent,
    DateTime? lastLoginAt,
    DateTime? trustedUntil,
    double? lat,
    double? lng,
    bool? isRevoked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrustedDeviceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      lastIp: lastIp ?? this.lastIp,
      userAgent: userAgent ?? this.userAgent,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      trustedUntil: trustedUntil ?? this.trustedUntil,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isRevoked: isRevoked ?? this.isRevoked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}