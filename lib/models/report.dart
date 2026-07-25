import 'enums.dart';

class Report {
  final String id;
  final String reportCode;
  final IssueCategory category;
  final Severity severity;
  final ReportStatus status;
  final String? description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final int confirmationsCount;
  final String? authorityName;
  final String? authorityEmail;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reportCode,
    required this.category,
    required this.severity,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.confirmationsCount,
    required this.createdAt,
    this.description,
    this.imageUrl,
    this.address,
    this.city,
    this.authorityName,
    this.authorityEmail,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    final authority = json['authority'] as Map<String, dynamic>?;
    return Report(
      id: json['id'] as String,
      reportCode: json['report_code'] as String,
      category: IssueCategory.fromWire(json['category'] as String),
      severity: Severity.fromWire(json['severity'] as String),
      status: ReportStatus.fromWire(json['status'] as String),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      confirmationsCount: (json['confirmations_count'] as num?)?.toInt() ?? 0,
      authorityName: authority?['department_name'] as String?,
      authorityEmail: authority?['email'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SubmitResult {
  final Report report;
  final String? authorityContacted;
  const SubmitResult({required this.report, this.authorityContacted});

  factory SubmitResult.fromJson(Map<String, dynamic> json) => SubmitResult(
        report: Report.fromJson(json['report'] as Map<String, dynamic>),
        authorityContacted: json['authority_contacted'] as String?,
      );
}
