import 'package:flutter/material.dart';

/// Issue categories — mirror the backend wire values.
enum IssueCategory {
  pothole, garbage, brokenStreetlight, waterLeakage,
  sewageOverflow, openManhole, damagedRoad, other;

  String get wire => switch (this) {
        IssueCategory.pothole => 'pothole',
        IssueCategory.garbage => 'garbage',
        IssueCategory.brokenStreetlight => 'broken_streetlight',
        IssueCategory.waterLeakage => 'water_leakage',
        IssueCategory.sewageOverflow => 'sewage_overflow',
        IssueCategory.openManhole => 'open_manhole',
        IssueCategory.damagedRoad => 'damaged_road',
        IssueCategory.other => 'other',
      };

  String get label => switch (this) {
        IssueCategory.pothole => 'Pothole',
        IssueCategory.garbage => 'Garbage',
        IssueCategory.brokenStreetlight => 'Broken Streetlight',
        IssueCategory.waterLeakage => 'Water Leakage',
        IssueCategory.sewageOverflow => 'Sewage Overflow',
        IssueCategory.openManhole => 'Open Manhole',
        IssueCategory.damagedRoad => 'Damaged Road',
        IssueCategory.other => 'Other',
      };

  IconData get icon => switch (this) {
        IssueCategory.pothole => Icons.dangerous_outlined,
        IssueCategory.garbage => Icons.delete_outline,
        IssueCategory.brokenStreetlight => Icons.lightbulb_outline,
        IssueCategory.waterLeakage => Icons.water_drop_outlined,
        IssueCategory.sewageOverflow => Icons.water_damage_outlined,
        IssueCategory.openManhole => Icons.warning_amber_outlined,
        IssueCategory.damagedRoad => Icons.remove_road_outlined,
        IssueCategory.other => Icons.report_outlined,
      };

  static IssueCategory fromWire(String v) =>
      IssueCategory.values.firstWhere((c) => c.wire == v,
          orElse: () => IssueCategory.other);
}

enum ReportStatus {
  unresolved, underReview, resolved;

  String get wire => switch (this) {
        ReportStatus.unresolved => 'unresolved',
        ReportStatus.underReview => 'under_review',
        ReportStatus.resolved => 'resolved',
      };

  String get label => switch (this) {
        ReportStatus.unresolved => 'Unresolved',
        ReportStatus.underReview => 'Under Review',
        ReportStatus.resolved => 'Resolved',
      };

  Color get color => switch (this) {
        ReportStatus.unresolved => const Color(0xFFC0392B),
        ReportStatus.underReview => const Color(0xFFC9880A),
        ReportStatus.resolved => const Color(0xFF1E7B4F),
      };

  static ReportStatus fromWire(String v) =>
      ReportStatus.values.firstWhere((s) => s.wire == v,
          orElse: () => ReportStatus.unresolved);
}

enum Severity {
  low, medium, high, critical;

  String get label => name[0].toUpperCase() + name.substring(1);

  Color get color => switch (this) {
        Severity.low => const Color(0xFF1E7B4F),
        Severity.medium => const Color(0xFFC9880A),
        Severity.high => const Color(0xFFD35400),
        Severity.critical => const Color(0xFFC0392B),
      };

  static Severity fromWire(String v) => Severity.values
      .firstWhere((s) => s.name == v, orElse: () => Severity.medium);
}

enum SocialPlatform {
  x, facebook;

  String get label => this == SocialPlatform.x ? 'X (Twitter)' : 'Facebook';
  String get composeUrl => this == SocialPlatform.x
      ? 'https://x.com/compose/post'
      : 'https://www.facebook.com/';

  static SocialPlatform fromWire(String v) =>
      v == 'x' ? SocialPlatform.x : SocialPlatform.facebook;
}

enum SocialPostStatus {
  ready, posted, skipped;

  String get label => switch (this) {
        SocialPostStatus.ready => 'Awaiting review',
        SocialPostStatus.posted => 'Posted',
        SocialPostStatus.skipped => 'Skipped',
      };

  static SocialPostStatus fromWire(String v) => SocialPostStatus.values
      .firstWhere((s) => s.name == v, orElse: () => SocialPostStatus.ready);
}

enum ConfirmationType {
  confirmExists, markFixed;

  String get wire =>
      this == ConfirmationType.confirmExists ? 'confirm_exists' : 'mark_fixed';
}
