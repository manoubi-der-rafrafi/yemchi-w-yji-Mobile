import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yemchi_wyji/core/env.dart';
import 'package:yemchi_wyji/core/errors/application_error_service.dart';
import 'package:yemchi_wyji/core/storage/token_storage.dart';

class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static Future<bool>? _refreshInFlight;

  Uri _u(String path) => Uri.parse('${Env.baseUrl}$path');

  void _log(String message) {
    if (kDebugMode) debugPrint('[API] $message');
  }

  Future<Map<String, String>> _headers({bool includeAuth = true}) async {
    final token = await TokenStorage.access();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Type': 'mobile',
    };
    if (includeAuth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path, {bool includeAuth = true}) async {
    final uri = _u(path);
    _log('REQ GET $uri includeAuth=$includeAuth');
    final r = await _sendWithRefresh(
      'GET',
      uri,
      includeAuth,
      () async =>
          _client.get(uri, headers: await _headers(includeAuth: includeAuth)),
    );
    _log('RES ${r.statusCode} GET $uri body=${_truncate(r.body)}');
    _throwIfError(r);
    return r;
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? extraHeaders,
    bool includeAuth = true,
  }) async {
    final uri = _u(path);
    _log('REQ POST $uri includeAuth=$includeAuth body=${_safeBody(body)}');
    final r = await _sendWithRefresh(
      'POST',
      uri,
      includeAuth,
      () async => _client.post(
        uri,
        headers: {
          ...await _headers(includeAuth: includeAuth),
          ...?extraHeaders,
        },
        body: body,
      ),
    );
    _log('RES ${r.statusCode} POST $uri body=${_truncate(r.body)}');
    _throwIfError(r);
    return r;
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    bool includeAuth = true,
  }) async {
    final uri = _u(path);
    _log('REQ PUT $uri includeAuth=$includeAuth body=${_safeBody(body)}');
    final r = await _sendWithRefresh(
      'PUT',
      uri,
      includeAuth,
      () async => _client.put(
        uri,
        headers: await _headers(includeAuth: includeAuth),
        body: body,
      ),
    );
    _log('RES ${r.statusCode} PUT $uri body=${_truncate(r.body)}');
    _throwIfError(r);
    return r;
  }

  Future<http.Response> delete(String path, {bool includeAuth = true}) async {
    final uri = _u(path);
    _log('REQ DELETE $uri includeAuth=$includeAuth');
    final r = await _sendWithRefresh(
      'DELETE',
      uri,
      includeAuth,
      () async => _client.delete(
        uri,
        headers: await _headers(includeAuth: includeAuth),
      ),
    );
    _log('RES ${r.statusCode} DELETE $uri body=${_truncate(r.body)}');
    _throwIfError(r);
    return r;
  }

  Future<http.Response> patch(
    String path, {
    Object? body,
    bool includeAuth = true,
  }) async {
    final uri = _u(path);
    _log('REQ PATCH $uri includeAuth=$includeAuth body=${_safeBody(body)}');
    final r = await _sendWithRefresh(
      'PATCH',
      uri,
      includeAuth,
      () async => _client.patch(
        uri,
        headers: await _headers(includeAuth: includeAuth),
        body: body,
      ),
    );
    _log('RES ${r.statusCode} PATCH $uri body=${_truncate(r.body)}');
    _throwIfError(r);
    return r;
  }

  void _throwIfError(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;

    final req = r.request;
    _log('${req?.method ?? "HTTP"} ${req?.url} -> ${r.statusCode}');
    _log('Response body: ${r.body}');
    ApplicationErrorService.report(
      'HTTP ${r.statusCode} ${req?.method ?? "HTTP"} ${req?.url.path ?? ""}',
      type: 'http_error',
      severity: r.statusCode >= 500 ? 'error' : 'warning',
      endpoint: req?.url.path,
      httpStatus: r.statusCode,
      metadata: {'method': req?.method ?? 'HTTP'},
    );

    throw ApiException(r.statusCode, _safeMsg(r.body));
  }

  Future<http.Response> _execute(
    String method,
    Uri uri,
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } catch (error, stackTrace) {
      unawaited(
        ApplicationErrorService.report(
          error,
          stackTrace: stackTrace,
          type: 'network_error',
          endpoint: uri.path,
          metadata: {'method': method},
        ),
      );
      rethrow;
    }
  }

  Future<http.Response> _sendWithRefresh(
    String method,
    Uri uri,
    bool includeAuth,
    Future<http.Response> Function() request,
  ) async {
    if (includeAuth &&
        await TokenStorage.isAccessExpired() &&
        await TokenStorage.hasRefresh()) {
      await _refreshAccessToken();
    }

    var response = await _execute(method, uri, request);
    if (includeAuth &&
        response.statusCode == 401 &&
        await _refreshAccessToken()) {
      response = await _execute(method, uri, request);
    }
    return response;
  }

  Future<bool> _refreshAccessToken() {
    final current = _refreshInFlight;
    if (current != null) return current;
    final operation = _performRefresh();
    _refreshInFlight = operation;
    operation.whenComplete(() {
      if (identical(_refreshInFlight, operation)) _refreshInFlight = null;
    });
    return operation;
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await TokenStorage.refresh();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _client.post(
        _u('/auth/refresh'),
        headers: await _headers(includeAuth: false),
        body: json.encode({'refreshToken': refreshToken}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 400 || response.statusCode == 401) {
          await TokenStorage.clear();
        }
        return false;
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final access =
          data['token']?.toString() ?? data['accessToken']?.toString();
      final rotatedRefresh = data['refreshToken']?.toString();
      if (access == null ||
          access.isEmpty ||
          rotatedRefresh == null ||
          rotatedRefresh.isEmpty) {
        await TokenStorage.clear();
        return false;
      }
      await TokenStorage.save(
        access: access,
        refresh: rotatedRefresh,
        userId: await TokenStorage.userId(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> authenticatedAccessToken() async {
    if (await TokenStorage.isAccessExpired() &&
        await TokenStorage.hasRefresh()) {
      await _refreshAccessToken();
    }
    return TokenStorage.access();
  }

  String _safeMsg(String body) {
    try {
      final m = json.decode(body);
      if (m is Map && m['message'] != null) return m['message'].toString();
      if (m is Map && m['error'] != null) return m['error'].toString();
      return body;
    } catch (_) {
      return body;
    }
  }

  String _safeBody(Object? body) {
    if (body == null) return 'null';
    try {
      final decoded = body is String ? json.decode(body) : body;
      if (decoded is Map) {
        final redacted = Map<String, dynamic>.from(decoded);
        redacted.remove('motDePasse');
        redacted.remove('password');
        redacted.remove('token');
        redacted.remove('accessToken');
        return json.encode(redacted);
      }
    } catch (_) {}
    return body.toString();
  }

  String _truncate(String input, {int max = 700}) {
    if (input.length <= max) return input;
    return '${input.substring(0, max)}...';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
