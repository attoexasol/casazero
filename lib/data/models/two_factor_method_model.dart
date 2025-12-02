// data/models/two_factor_method_model.dart

class TwoFactorMethod {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isEnabled;
  final bool isConfigured;
  final TwoFactorMethodType type;

  TwoFactorMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isEnabled = false,
    this.isConfigured = false,
    required this.type,
  });

  TwoFactorMethod copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? isEnabled,
    bool? isConfigured,
    TwoFactorMethodType? type,
  }) {
    return TwoFactorMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isEnabled: isEnabled ?? this.isEnabled,
      isConfigured: isConfigured ?? this.isConfigured,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'isEnabled': isEnabled,
      'isConfigured': isConfigured,
      'type': type.name,
    };
  }

  factory TwoFactorMethod.fromJson(Map<String, dynamic> json) {
    return TwoFactorMethod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      isConfigured: json['isConfigured'] ?? false,
      type: TwoFactorMethodType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => TwoFactorMethodType.authenticator,
      ),
    );
  }
}

enum TwoFactorMethodType {
  email,
  sms,
  authenticator,
}

extension TwoFactorMethodTypeExtension on TwoFactorMethodType {
  String get name {
    return toString().split('.').last;
  }
}