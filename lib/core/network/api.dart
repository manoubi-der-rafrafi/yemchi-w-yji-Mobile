import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yemchi_wyji/core/env.dart';
import 'package:yemchi_wyji/core/storage/token_storage.dart';

class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri _u(String path) => Uri.parse('${Env.baseUrl}$path');


  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[API] $message');
    }
  }

  bool _isSensitiveKey(String key) {
    final k = key.toLowerCase();
    return k.contains('authorization') ||
        k.contains('password') ||
        k.contains('motdepasse') ||
        k.contains('token') ||
        k.contains('refresh');
  }

  dynamic _redact(dynamic value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) {
        final key = k.toString();
        out[key] = _isSensitiveKey(key) ? '***' : _redact(v);
      });
      return out;
    }
    if (value is List) {
      return value.map(_redact).toList();
    }
    return value;
  }

  String _safeForLog(dynamic value) {
    if (value == null) return 'null';
    try {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          final parsed = json.decode(trimmed);
          return json.encode(_redact(parsed));
        }
        return value;
      }
      return json.encode(_redact(value));
    } catch (_) {
      return value.toString();
    }
  }

  String _truncate(String input, {int max = 600}) {
    if (input.length <= max) return input;
    return '${input.substring(0, max)}...';
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final token = await TokenStorage.access();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }


  Future<http.Response> get(String path, {bool withAuth = true}) async {
    final uri = _u(path);
    final headers = await _headers(withAuth: withAuth);
    _log('REQ GET $uri withAuth=$withAuth headers=${_safeForLog(headers)}');
    final r = await _client.get(uri, headers: headers);
    _log('RES ${r.statusCode} GET $uri body=${_truncate(_safeForLog(r.body))}');
    _throwIfError(r);
    return r;
  }

  Future<http.Response> post(
    String path, {
    Object? body,

    bool withAuth = true,
  }) async {
    final uri = _u(path);
    final headers = await _headers(withAuth: withAuth);
    _log(
      'REQ POST $uri withAuth=$withAuth headers=${_safeForLog(headers)} '
      'body=${_truncate(_safeForLog(body))}',
    );
    final r = await _client.post(uri, headers: headers, body: body);
    _log(
      'RES ${r.statusCode} POST $uri body=${_truncate(_safeForLog(r.body))}',
    );
    _throwIfError(r);
    return r;
  }

  Future<http.Response> put(
    String path, {
    Object? body,

    bool withAuth = true,
  }) async {
    final uri = _u(path);
    final headers = await _headers(withAuth: withAuth);
    _log(
      'REQ PUT $uri withAuth=$withAuth headers=${_safeForLog(headers)} '
      'body=${_truncate(_safeForLog(body))}',
    );
    final r = await _client.put(uri, headers: headers, body: body);
    _log('RES ${r.statusCode} PUT $uri body=${_truncate(_safeForLog(r.body))}');
    _throwIfError(r);
    return r;
  }

  Future<http.Response> delete(String path, {bool withAuth = true}) async {
    final uri = _u(path);
    final headers = await _headers(withAuth: withAuth);
    _log('REQ DELETE $uri withAuth=$withAuth headers=${_safeForLog(headers)}');
    final r = await _client.delete(uri, headers: headers);
    _log(
      'RES ${r.statusCode} DELETE $uri body=${_truncate(_safeForLog(r.body))}',
    );
    _throwIfError(r);
    return r;
  }
  //patch
  Future<http.Response> patch(
    String path, {
    Object? body,
    bool withAuth = true,
  }) async {
    final uri = _u(path);
    final headers = await _headers(withAuth: withAuth);
    _log(
      'REQ PATCH $uri withAuth=$withAuth headers=${_safeForLog(headers)} '
      'body=${_truncate(_safeForLog(body))}',
    );
    final r = await _client.patch(uri, headers: headers, body: body);
    _log(
      'RES ${r.statusCode} PATCH $uri body=${_truncate(_safeForLog(r.body))}',
    );
    _throwIfError(r);
    return r;
  }

  void _throwIfError(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;

    final req = r.request;
    _log(
      'ERROR ${req?.method ?? "HTTP"} ${req?.url} -> ${r.statusCode} '
      'body=${_truncate(_safeForLog(r.body))}',
    );

    throw ApiException(r.statusCode, _safeMsg(r.body));
  }

  String _safeMsg(String body) {
    try {
      final m = json.decode(body);
      if (m is Map && m['message'] != null) return m['message'].toString();
      return body;
    } catch (_) {
      return body;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
