class IssueTypeModel {
  final int id;
  final String issueType;

  const IssueTypeModel({
    required this.id,
    required this.issueType,
  });

  factory IssueTypeModel.fromJson(Map<String, dynamic> json) {
    return IssueTypeModel(
      id: json['id'] ?? 0,
      issueType: json['issue_type'] ?? '',
    );
  }
}
