import 'enums.dart';
import 'report.dart';

class SocialPost {
  final String id;
  final SocialPlatform platform;
  final String content;
  final String? postUrl;
  final SocialPostStatus status;
  final String? note;
  final DateTime createdAt;
  final DateTime? postedAt;
  final Report? report;

  const SocialPost({
    required this.id,
    required this.platform,
    required this.content,
    required this.status,
    required this.createdAt,
    this.postUrl,
    this.note,
    this.postedAt,
    this.report,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
        id: json['id'] as String,
        platform: SocialPlatform.fromWire(json['platform'] as String),
        content: json['content'] as String,
        postUrl: json['post_url'] as String?,
        status: SocialPostStatus.fromWire(json['status'] as String),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        postedAt: json['posted_at'] == null
            ? null
            : DateTime.parse(json['posted_at'] as String),
        report: json['report'] == null
            ? null
            : Report.fromJson(json['report'] as Map<String, dynamic>),
      );
}
