import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yemchi_wyji/core/env.dart';
import 'package:yemchi_wyji/core/storage/token_storage.dart';

class ApplicationErrorService {
  static bool _reporting = false;

  static Future<void> report(
    Object error, {
    StackTrace? stackTrace,
    String type = 'unknown',
    String severity = 'error',
    String? page,
    String? endpoint,
    int? httpStatus,
    Map<String, Object?> metadata = const {},
  }) async {
    if (_reporting) return;
    _reporting = true;
    try {
      final token = await TokenStorage.access();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = jsonEncode({
        'message': _redact(error.toString(), 1200),
        'type': _redact(type, 100),
        'source': 'mobile_driver',
        'severity': severity,
        'page': _safeEndpoint(page),
        'endpoint': _safeEndpoint(endpoint),
        'httpStatus': httpStatus,
        'stackTrace': _redact(stackTrace?.toString(), 5000),
        'metadata': _sanitizeMetadata(metadata),
        'deviceType': defaultTargetPlatform.name,
        'appVersion': '1.0.0',
      });

      final response = await http.post(
        Uri.parse('${Env.baseUrl}/errors'),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 401 && token != null) {
        await http.post(
          Uri.parse('${Env.baseUrl}/errors'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        );
      }
    } catch (reason) {
      if (kDebugMode) debugPrint('[Errors] report ignored: $reason');
    } finally {
      _reporting = false;
    }
  }

  static Map<String, Object?> _sanitizeMetadata(Map<String, Object?> metadata) {
    final output = <String, Object?>{};
    for (final entry in metadata.entries.take(20)) {
      if (_isSensitiveKey(entry.key)) continue;
      final value = entry.value;
      final key =
          entry.key.length > 80 ? entry.key.substring(0, 80) : entry.key;
      output[key] = value is String ? _redact(value, 300) : value;
    }
    return output;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return const [
      'password',
      'motdepasse',
      'token',
      'authorization',
      'cookie',
      'secret',
      'image',
      'base64',
      'latitude',
      'longitude',
      'coordinates',
    ].any(normalized.contains);
  }

  static String? _safeEndpoint(String? value) {
    if (value == null || value.isEmpty) return null;
    final path = value.split('?').first;
    return path.length > 300 ? path.substring(0, 300) : path;
  }

  static String? _redact(String? value, int max) {
    if (value == null || value.isEmpty) return null;
    var clean = value
        .replaceAll(
          RegExp(r'bearer\s+[a-z0-9._~+\-/]+=*', caseSensitive: false),
          'Bearer [REDACTED]',
        )
        .replaceAll(
          RegExp(
            r'\beyJ[a-z0-9_-]+\.[a-z0-9_-]+\.[a-z0-9_-]+\b',
            caseSensitive: false,
          ),
          '[REDACTED_TOKEN]',
        )
        .replaceAll(
          RegExp(
            r'(password|motDePasse|token|accessToken|refreshToken|authorization|secret)\s*[:=]\s*[^\s,;]+',
            caseSensitive: false,
          ),
          r'$1=[REDACTED]',
        );
    if (clean.length > max) clean = clean.substring(0, max);
    return clean;
  }
}
