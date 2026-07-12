// data/models/residence_model.dart

class ResidenceModel {
  final int id;
  final String residenceName;
  final String? residenceAddress;
  final String? unitName;
  final String residenceType;
  final int residenceAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? residencePhoto;
  final String? residenceStatus;

  ResidenceModel({
    required this.id,
    required this.residenceName,
    this.residenceAddress,
    this.unitName,
    required this.residenceType,
    required this.residenceAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.residencePhoto,
    this.residenceStatus,
  });

  factory ResidenceModel.fromJson(Map<String, dynamic> json) {
    return ResidenceModel(
      id: json['id'] ?? 0,
      residenceName: json['residence_name'] ?? '',
      residenceAddress: json['residence_address'],
      unitName: _parseUnitName(json),
      residenceType: json['residence_type'] ?? '',
      residenceAdmin: json['residence_admin'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      residencePhoto: json['residence_photo'],
      residenceStatus: json['residence_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residence_name': residenceName,
      'residence_address': residenceAddress,
      'unit_name': unitName,
      'residence_type': residenceType,
      'residence_admin': residenceAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'residence_photo': residencePhoto,
      'residence_status': residenceStatus,
    };
  }

  static String? _parseUnitName(Map<String, dynamic> json) {
    final direct = json['unit_name']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final unit = json['unit'];
    if (unit is Map) {
      final nested = unit['unit_name']?.toString().trim();
      if (nested != null && nested.isNotEmpty) return nested;
    }
    return null;
  }

  // Display name with address if available
  String get displayName {
    if (residenceAddress != null && residenceAddress!.isNotEmpty) {
      return '$residenceName - $residenceAddress';
    }
    return residenceName;
  }

  // Copy with method for updating
  ResidenceModel copyWith({
    int? id,
    String? residenceName,
    String? residenceAddress,
    String? unitName,
    String? residenceType,
    int? residenceAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? residencePhoto,
    String? residenceStatus,
  }) {
    return ResidenceModel(
      id: id ?? this.id,
      residenceName: residenceName ?? this.residenceName,
      residenceAddress: residenceAddress ?? this.residenceAddress,
      unitName: unitName ?? this.unitName,
      residenceType: residenceType ?? this.residenceType,
      residenceAdmin: residenceAdmin ?? this.residenceAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      residencePhoto: residencePhoto ?? this.residencePhoto,
      residenceStatus: residenceStatus ?? this.residenceStatus,
    );
  }

  @override
  String toString() {
    return 'ResidenceModel(id: $id, name: $residenceName, type: $residenceType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResidenceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}