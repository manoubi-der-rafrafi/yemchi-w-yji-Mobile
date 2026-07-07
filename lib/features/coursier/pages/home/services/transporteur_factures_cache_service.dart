import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:yemchi_wyji/core/models/facture.dart';

class TransporteurFacturesCacheEntry {
  const TransporteurFacturesCacheEntry({
    required this.transporteurId,
    required this.cachedAt,
    required this.factures,
  });

  final String transporteurId;
  final DateTime cachedAt;
  final List<Facture> factures;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'transporteurId': transporteurId,
      'cachedAt': cachedAt.toIso8601String(),
      'factures': factures.map((f) => f.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());

  factory TransporteurFacturesCacheEntry.fromMap(Map<String, dynamic> map) {
    final rawFactures = map['factures'];
    return TransporteurFacturesCacheEntry(
      transporteurId: (map['transporteurId'] ?? '').toString(),
      cachedAt:
          DateTime.tryParse((map['cachedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      factures:
          rawFactures is List
              ? rawFactures
                  .whereType<Map>()
                  .map((item) => Facture.fromMap(item.cast<String, dynamic>()))
                  .toList(growable: false)
              : const <Facture>[],
    );
  }

  factory TransporteurFacturesCacheEntry.fromJson(String source) {
    return TransporteurFacturesCacheEntry.fromMap(
      json.decode(source) as Map<String, dynamic>,
    );
  }
}

class TransporteurFacturesCacheService {
  static const String _keyPrefix = 'transporteur_factures_';

  Future<TransporteurFacturesCacheEntry?> read(String transporteurId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$transporteurId');
    if (raw == null || raw.isEmpty) return null;
    try {
      return TransporteurFacturesCacheEntry.fromJson(raw);
    } catch (_) {
      await prefs.remove('$_keyPrefix$transporteurId');
      return null;
    }
  }

  Future<void> write(TransporteurFacturesCacheEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix${entry.transporteurId}', entry.toJson());
  }
}
