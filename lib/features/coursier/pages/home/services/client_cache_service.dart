import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';

class ClientCacheService {
  static const String _keyPrefix = 'transporteur_client_';

  Future<Utilisateur?> read(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$clientId');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Utilisateur.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove('$_keyPrefix$clientId');
      return null;
    }
  }

  Future<void> write(Utilisateur user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix${user.id}', json.encode(user.toJson()));
  }

  Future<void> clear(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$clientId');
  }
}
