class IssueTypeModel {
  final int id;
  final String issueTypeEn;
  final String issueTypeIt;

  const IssueTypeModel({
    required this.id,
    required this.issueTypeEn,
    this.issueTypeIt = '',
  });

  factory IssueTypeModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return IssueTypeModel(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      issueTypeEn: json['issue_type_en']?.toString() ?? '',
      issueTypeIt: json['issue_type_it']?.toString() ?? '',
    );
  }

  /// Returns the localized issue type name based on the given locale code.
  String localizedName(String languageCode) {
    if (languageCode == 'it' && issueTypeIt.isNotEmpty) {
      return issueTypeIt;
    }
    return issueTypeEn;
  }
}
