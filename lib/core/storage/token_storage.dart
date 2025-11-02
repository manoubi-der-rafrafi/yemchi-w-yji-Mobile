import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage sécurisé des JWT (access + refresh) dans le coffre système.
/// - iOS: Keychain
/// - Android: Keystore + EncryptedSharedPreferences
class TokenStorage {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUserId = 'user_id';
  static const FlutterSecureStorage _s = FlutterSecureStorage();

  /// Sauvegarde (rotation possible)
  static Future<void> save({
    required String access,
    String? refresh,
    String? userId,
  }) async {
    await _s.write(key: _kAccess, value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _s.write(key: _kRefresh, value: refresh);
    }
    if (userId != null && userId.isNotEmpty) {
      await _s.write(key: _kUserId, value: userId);
    }
  }

  static Future<String?> access()  => _s.read(key: _kAccess);
  static Future<String?> refresh() => _s.read(key: _kRefresh);
  static Future<String?> userId()  => _s.read(key: _kUserId);

  static Future<bool> hasAccess() async => (await access())?.isNotEmpty == true;
  static Future<bool> hasRefresh() async => (await refresh())?.isNotEmpty == true;
  static Future<bool> hasUserId() async => (await userId())?.isNotEmpty == true;

  /// Efface tout (logout)
  static Future<void> clear() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
    await _s.delete(key: _kUserId);
  }

  /// --------- Aides JWT (facultatif mais utile) ---------

  /// True si l'access token est expiré (ou invalide).
  /// Ajoute une marge (skew) pour anticiper les décalages d’horloge.
  static Future<bool> isAccessExpired({int skewSeconds = 30}) async {
    final t = await access();
    if (t == null || t.isEmpty) return true;
    final exp = _jwtExp(t);
    if (exp == null) return false; // token opaque => on ne sait pas
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (exp - skewSeconds) <= now;
  }

  /// Secondes restantes avant expiration (null si inconnu).
  static Future<int?> accessRemainingSeconds() async {
    final t = await access();
    final exp = t == null ? null : _jwtExp(t);
    if (exp == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return exp - now;
  }

  /// Décode le payload du JWT (non vérifié cryptographiquement).
  static Future<Map<String, dynamic>?> accessPayload() async {
    final t = await access();
    if (t == null) return null;
    return _jwtPayload(t);
  }

  /// --- helpers internes ---

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
      case 2: normalized += '=='; break;
      case 3: normalized += '='; break;
      case 0: break;
      default: throw const FormatException('Invalid Base64URL');
    }
    return utf8.decode(base64.decode(normalized));
  }
}
