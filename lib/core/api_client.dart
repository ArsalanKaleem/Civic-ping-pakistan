import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

/// Thin HTTP wrapper. The auth token is supplied lazily by [tokenProvider]
/// so a freshly-refreshed Firebase ID token is attached to every request.
class ApiClient {
  ApiClient({String? baseUrl}) : _base = baseUrl ?? AppConfig.apiBaseUrl;

  final String _base;

  /// Returns the current bearer token (Firebase ID token or legacy JWT).
  Future<String?> Function()? tokenProvider;

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = tokenProvider == null ? null : await tokenProvider!();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$_base$path').replace(queryParameters: q);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      _decode(await http.get(_uri(path, query), headers: await _headers()));

  Future<dynamic> post(String path,
          {Object? body, Map<String, dynamic>? query}) async =>
      _decode(await http.post(_uri(path, query),
          headers: await _headers(),
          body: body == null ? null : jsonEncode(body)));

  Future<dynamic> patch(String path, {Object? body}) async =>
      _decode(await http.patch(_uri(path),
          headers: await _headers(),
          body: body == null ? null : jsonEncode(body)));

  Future<dynamic> delete(String path) async =>
      _decode(await http.delete(_uri(path), headers: await _headers()));

  /// Multipart image upload -> returns {url, filename, size_bytes}.
  Future<Map<String, dynamic>> uploadImage(
      List<int> bytes, String filename) async {
    final req = http.MultipartRequest('POST', _uri('/uploads'));
    final headers = await _headers(json: false);
    req.headers.addAll(headers);
    req.files.add(http.MultipartFile.fromBytes('file', bytes,
        filename: filename));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res) as Map<String, dynamic>;
  }

  dynamic _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    if (!ok) {
      String message = 'Request failed (${res.statusCode})';
      try {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(res.statusCode, message);
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
}
