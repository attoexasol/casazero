/// API response model for /residence/status-with-phases.
/// Each phase has bilingual names and optional status (description, date, image).
class ResidenceStatusPhaseModel {
  final int phaseId;
  final String phaseNameEn;
  final String phaseNameIt;
  final bool isCompleted;
  final PhaseStatusInfo? status;

  ResidenceStatusPhaseModel({
    required this.phaseId,
    required this.phaseNameEn,
    required this.phaseNameIt,
    required this.isCompleted,
    this.status,
  });

  factory ResidenceStatusPhaseModel.fromJson(Map<String, dynamic> json) {
    PhaseStatusInfo? statusInfo;
    if (json['status'] != null && json['status'] is Map) {
      statusInfo = PhaseStatusInfo.fromJson(
        Map<String, dynamic>.from(json['status'] as Map),
      );
    }
    return ResidenceStatusPhaseModel(
      phaseId: (json['phase_id'] is int)
          ? json['phase_id'] as int
          : int.tryParse(json['phase_id']?.toString() ?? '0') ?? 0,
      phaseNameEn: json['phase_name_en']?.toString() ?? '',
      phaseNameIt: json['phase_name_it']?.toString() ?? '',
      isCompleted: json['is_completed'] == true,
      status: statusInfo,
    );
  }
}

class PhaseStatusInfo {
  final String? statusDescription;
  final String? statusDate;
  final String? image;

  PhaseStatusInfo({
    this.statusDescription,
    this.statusDate,
    this.image,
  });

  factory PhaseStatusInfo.fromJson(Map<String, dynamic> json) {
    return PhaseStatusInfo(
      statusDescription: json['status_description']?.toString(),
      statusDate: json['status_date']?.toString(),
      image: json['image']?.toString(),
    );
  }
}
