class ConstructionPhaseModel {
  final String id;
  final String name;
  final String status; // 'completed', 'in-progress', 'pending'
  final int progress;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  ConstructionPhaseModel({
    required this.id,
    required this.name,
    required this.status,
    required this.progress,
    this.startDate,
    this.endDate,
    this.description,
  });

  factory ConstructionPhaseModel.fromJson(Map<String, dynamic> json) {
    return ConstructionPhaseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'pending',
      progress: json['progress'] ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'progress': progress,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'description': description,
    };
  }
}