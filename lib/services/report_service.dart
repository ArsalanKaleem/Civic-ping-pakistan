import '../core/api_client.dart';
import '../models/enums.dart';
import '../models/report.dart';

class ReportService {
  ReportService(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> uploadImage(
          List<int> bytes, String filename) =>
      _api.uploadImage(bytes, filename);

  Future<SubmitResult> submit({
    required IssueCategory category,
    required double latitude,
    required double longitude,
    String? description,
    String? imageUrl,
    String? address,
    String? city,
  }) async {
    final data = await _api.post('/reports', body: {
      'category': category.wire,
      'latitude': latitude,
      'longitude': longitude,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (address != null && address.isNotEmpty) 'address': address,
      if (city != null && city.isNotEmpty) 'city': city,
    });
    return SubmitResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Report>> list({
    ReportStatus? status,
    IssueCategory? category,
    String? city,
    int limit = 200,
  }) async {
    final data = await _api.get('/reports', query: {
      if (status != null) 'status': status.wire,
      if (category != null) 'category': category.wire,
      if (city != null) 'city': city,
      'limit': limit,
    });
    return (data as List)
        .map((e) => Report.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Report> getByCode(String code) async =>
      Report.fromJson(await _api.get('/reports/$code') as Map<String, dynamic>);

  Future<void> confirm({
    required String code,
    required ConfirmationType type,
    String? comment,
  }) =>
      _api.post('/reports/$code/confirm', body: {
        'type': type.wire,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
}
