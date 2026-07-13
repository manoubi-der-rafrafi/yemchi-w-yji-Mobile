import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Token storage using SharedPreferences.
/// Fast and reliable on both emulator and real devices.
class TokenStorage {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUserId = 'user_id';

  // ── Write ──────────────────────────────────────────────────────────
  static Future<void> save({
    required String access,
    String? refresh,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    if (refresh != null && refresh.isNotEmpty) {
      await prefs.setString(_kRefresh, refresh);
    }
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_kUserId, userId);
    }
  }

  // ── Read ───────────────────────────────────────────────────────────
  static Future<String?> access() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccess);
  }

  static Future<String?> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefresh);
  }

  static Future<String?> userId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserId);
  }

  static Future<bool> hasAccess() async =>
      ((await access())?.isNotEmpty) == true;
  static Future<bool> hasRefresh() async =>
      ((await refresh())?.isNotEmpty) == true;
  static Future<bool> hasUserId() async =>
      ((await userId())?.isNotEmpty) == true;

  // ── Clear (logout) ─────────────────────────────────────────────────
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kUserId);
  }

  // ── JWT helpers ────────────────────────────────────────────────────
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
      return json.decode(_base64UrlDecode(parts[1])) as Map<String, dynamic>;
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
    String s = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (s.length % 4) {
      case 2: s += '=='; break;
      case 3: s += '=';  break;
    }
    return utf8.decode(base64.decode(s));
  }
}
