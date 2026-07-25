import 'package:flutter_test/flutter_test.dart';
import 'package:civicping/models/enums.dart';
import 'package:civicping/models/report.dart';
import 'package:civicping/models/social_post.dart';

void main() {
  group('wire mappings', () {
    test('IssueCategory round-trips', () {
      for (final c in IssueCategory.values) {
        expect(IssueCategory.fromWire(c.wire), c);
      }
    });
    test('ReportStatus round-trips and colours are distinct', () {
      for (final s in ReportStatus.values) {
        expect(ReportStatus.fromWire(s.wire), s);
      }
      expect(ReportStatus.values.map((s) => s.color).toSet().length,
          ReportStatus.values.length);
    });
    test('SocialPostStatus parses', () {
      expect(SocialPostStatus.fromWire('ready'), SocialPostStatus.ready);
      expect(SocialPostStatus.fromWire('posted'), SocialPostStatus.posted);
    });
  });

  group('json parsing', () {
    final reportJson = {
      'id': 'abc',
      'report_code': 'CP-2026-XYZ123',
      'category': 'open_manhole',
      'severity': 'critical',
      'status': 'unresolved',
      'description': 'near a school',
      'image_url': 'http://localhost:8000/media/x.jpg',
      'latitude': 24.86,
      'longitude': 67.0,
      'address': 'Shahrah-e-Faisal',
      'city': 'Karachi',
      'confirmations_count': 3,
      'authority': {
        'id': 'a1',
        'department_name': 'KW&SC',
        'email': 'x@authorities.example'
      },
      'created_at': '2026-07-05T10:00:00Z',
    };

    test('Report.fromJson', () {
      final r = Report.fromJson(reportJson);
      expect(r.category, IssueCategory.openManhole);
      expect(r.severity, Severity.critical);
      expect(r.authorityName, 'KW&SC');
      expect(r.confirmationsCount, 3);
    });

    test('SocialPost.fromJson with nested report', () {
      final p = SocialPost.fromJson({
        'id': 'p1',
        'platform': 'x',
        'content': 'Issue Reported…',
        'post_url': null,
        'status': 'ready',
        'note': null,
        'created_at': '2026-07-05T10:00:00Z',
        'posted_at': null,
        'report': reportJson,
      });
      expect(p.platform, SocialPlatform.x);
      expect(p.status, SocialPostStatus.ready);
      expect(p.report?.reportCode, 'CP-2026-XYZ123');
    });
  });
}
