import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUserId = 'user_id';
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<void> save({
    required String access,
    String? refresh,
    String? userId,
  }) async {
    await _write(_kAccess, access);
    if (refresh != null && refresh.isNotEmpty) {
      await _write(_kRefresh, refresh);
    }
    if (userId != null && userId.isNotEmpty) {
      await _write(_kUserId, userId);
    }
  }

  static Future<String?> access() => _read(_kAccess);
  static Future<String?> refresh() => _read(_kRefresh);
  static Future<String?> userId() => _read(_kUserId);

  static Future<bool> hasAccess() async => (await access())?.isNotEmpty == true;
  static Future<bool> hasRefresh() async =>
      (await refresh())?.isNotEmpty == true;
  static Future<bool> hasUserId() async => (await userId())?.isNotEmpty == true;

  static Future<void> clear() async {
    await _delete(_kAccess);
    await _delete(_kRefresh);
    await _delete(_kUserId);
  }

  static Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    await _secure.write(key: key, value: value);
  }

  static Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return _secure.read(key: key);
  }

  static Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    await _secure.delete(key: key);
  }

  static Future<bool> isAccessExpired({int skewSeconds = 30}) async {
    final t = await access();
    if (t == null || t.isEmpty) return true;
    final exp = _jwtExp(t);
    if (exp == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (exp - skewSeconds) <= now;
  }

  static Future<int?> accessRemainingSeconds() async {
    final t = await access();
    final exp = t == null ? null : _jwtExp(t);
    if (exp == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return exp - now;
  }

  static Future<Map<String, dynamic>?> accessPayload() async {
    final t = await access();
    if (t == null) return null;
    return _jwtPayload(t);
  }

  static Map<String, dynamic>? _jwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = _base64UrlDecode(parts[1]);
      return json.decode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static int? _jwtExp(String token) {
    final p = _jwtPayload(token);
    final exp = p?['exp'];
    if (exp is int) return exp;
    if (exp is String) return int.tryParse(exp);
    return null;
  }

  static String _base64UrlDecode(String input) {
    String normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
      case 0:
        break;
      default:
        throw const FormatException('Invalid Base64URL');
    }
    return utf8.decode(base64.decode(normalized));
  }
}
