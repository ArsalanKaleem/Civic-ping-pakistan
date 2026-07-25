import 'enums.dart';

class Authority {
  final String id;
  final String? city;
  final String? district;
  final IssueCategory issueType;
  final String departmentName;
  final String email;
  final String? phone;
  final bool isVerified;

  const Authority({
    required this.id,
    required this.issueType,
    required this.departmentName,
    required this.email,
    required this.isVerified,
    this.city,
    this.district,
    this.phone,
  });

  factory Authority.fromJson(Map<String, dynamic> json) => Authority(
        id: json['id'] as String,
        city: json['city'] as String?,
        district: json['district'] as String?,
        issueType: IssueCategory.fromWire(json['issue_type'] as String),
        departmentName: json['department_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
      );
}

class AdminStats {
  final int totalReports;
  final int unresolved;
  final int underReview;
  final int resolved;
  final int pendingSocialPosts;
  final int reportsLast7Days;

  const AdminStats({
    required this.totalReports,
    required this.unresolved,
    required this.underReview,
    required this.resolved,
    required this.pendingSocialPosts,
    required this.reportsLast7Days,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalReports: j['total_reports'] as int,
        unresolved: j['unresolved'] as int,
        underReview: j['under_review'] as int,
        resolved: j['resolved'] as int,
        pendingSocialPosts: j['pending_social_posts'] as int,
        reportsLast7Days: j['reports_last_7_days'] as int,
      );
}
