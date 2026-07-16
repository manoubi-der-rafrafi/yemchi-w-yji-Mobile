import 'package:shared_preferences/shared_preferences.dart';

import 'transporteur_stats_snapshot.dart';

class TransporteurStatsCacheService {
  static const String _keyPrefix = 'transporteur_stats_';

  Future<TransporteurStatsSnapshot?> read(String transporteurId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$transporteurId');
    if (raw == null || raw.isEmpty) return null;
    try {
      return TransporteurStatsSnapshot.fromJson(raw);
    } catch (_) {
      await prefs.remove('$_keyPrefix$transporteurId');
      return null;
    }
  }

  Future<void> write(TransporteurStatsSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix${snapshot.transporteurId}',
      snapshot.toJson(),
    );
  }

  Future<void> clear(String transporteurId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$transporteurId');
  }
}
