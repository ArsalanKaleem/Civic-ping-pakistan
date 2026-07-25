import '../core/api_client.dart';
import '../models/authority.dart';
import '../models/enums.dart';
import '../models/report.dart';
import '../models/social_post.dart';

class AdminService {
  AdminService(this._api);
  final ApiClient _api;

  Future<AdminStats> stats() async =>
      AdminStats.fromJson(await _api.get('/admin/stats') as Map<String, dynamic>);

  // --- Social review queue ------------------------------------------------ //
  Future<List<SocialPost>> socialPosts({SocialPostStatus? status}) async {
    final data = await _api.get('/admin/social-posts', query: {
      if (status != null) 'status': status.name,
    });
    return (data as List)
        .map((e) => SocialPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SocialPost> reviewSocialPost({
    required String id,
    required SocialPostStatus status,
    String? postUrl,
    String? note,
  }) async {
    final data = await _api.patch('/admin/social-posts/$id', body: {
      'status': status.name,
      if (postUrl != null) 'post_url': postUrl,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return SocialPost.fromJson(data as Map<String, dynamic>);
  }

  // --- Reports ------------------------------------------------------------ //
  Future<Report> updateReportStatus(String code, ReportStatus status) async {
    final data = await _api
        .patch('/reports/$code/status', body: {'status': status.wire});
    return Report.fromJson(data as Map<String, dynamic>);
  }

  // --- Authorities ---------------------------------------------------------//
  Future<List<Authority>> authorities() async {
    final data = await _api.get('/authorities');
    return (data as List)
        .map((e) => Authority.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Authority> createAuthority(Map<String, dynamic> body) async =>
      Authority.fromJson(
          await _api.post('/authorities', body: body) as Map<String, dynamic>);

  Future<Authority> updateAuthority(String id, Map<String, dynamic> body) async =>
      Authority.fromJson(await _api.patch('/authorities/$id', body: body)
          as Map<String, dynamic>);

  Future<void> deleteAuthority(String id) => _api.delete('/authorities/$id');

  // --- Email logs ----------------------------------------------------------//
  Future<List<Map<String, dynamic>>> emailLogs() async {
    final data = await _api.get('/admin/email-logs');
    return (data as List).cast<Map<String, dynamic>>();
  }
}
