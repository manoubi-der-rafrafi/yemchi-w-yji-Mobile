import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yemchi_wyji/core/env.dart';
import 'package:yemchi_wyji/core/storage/token_storage.dart';

class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _timeout = Duration(seconds: 15);

  Uri _u(String path) => Uri.parse('${Env.baseUrl}$path');

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.access();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    final r = await _client
        .get(_u(path), headers: await _headers())
        .timeout(_timeout);
    _throwIfError(r);
    return r;
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final r = await _client
        .post(_u(path), headers: await _headers(), body: body)
        .timeout(_timeout);
    _throwIfError(r);
    return r;
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final r = await _client
        .put(_u(path), headers: await _headers(), body: body)
        .timeout(_timeout);
    _throwIfError(r);
    return r;
  }

  Future<http.Response> delete(String path) async {
    final r = await _client
        .delete(_u(path), headers: await _headers())
        .timeout(_timeout);
    _throwIfError(r);
    return r;
  }

  Future<http.Response> patch(String path, {Object? body}) async {
    final r = await _client
        .patch(_u(path), headers: await _headers(), body: body)
        .timeout(_timeout);
    _throwIfError(r);
    return r;
  }

  void _throwIfError(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;

    final req = r.request;
    print(
      '[API ERROR] ${req?.method ?? "HTTP"} ${req?.url} -> ${r.statusCode}',
    );
    print('Response body: ${r.body}');

    // Try to extract a readable message from the response
    String message = r.body;
    try {
      final m = json.decode(r.body);
      if (m is Map) {
        message =
            (m['message'] ?? m['error'] ?? m['reason'] ?? r.body).toString();
      }
    } catch (_) {}

    throw ApiException(
      r.statusCode,
      message.isNotEmpty ? message : 'Erreur ${r.statusCode}',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
