import 'dart:convert';

import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/facture.dart';

class TransporteurStatsSnapshot {
  const TransporteurStatsSnapshot({
    required this.transporteurId,
    required this.cachedAt,
    required this.totalEnLigne,
    required this.totalHorsLigne,
    required this.pourcentageParSousZone,
    required this.commandesLivrees,
    required this.factures,
  });

  final String transporteurId;
  final DateTime cachedAt;
  final double totalEnLigne;
  final double totalHorsLigne;
  final Map<String, double> pourcentageParSousZone;
  final List<Commande> commandesLivrees;
  final List<Facture> factures;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'transporteurId': transporteurId,
      'cachedAt': cachedAt.toIso8601String(),
      'totalEnLigne': totalEnLigne,
      'totalHorsLigne': totalHorsLigne,
      'pourcentageParSousZone': pourcentageParSousZone,
      'commandesLivrees': commandesLivrees.map((c) => c.toJson()).toList(),
      'factures': factures.map((f) => f.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());

  factory TransporteurStatsSnapshot.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    Map<String, double> parsePercentages(dynamic raw) {
      if (raw is! Map) return const <String, double>{};
      return raw.map<String, double>(
        (key, value) => MapEntry(key.toString(), toDouble(value)),
      );
    }

    List<Commande> parseCommandes(dynamic raw) {
      if (raw is! List) return const <Commande>[];
      return raw
          .whereType<Map>()
          .map((item) => Commande.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    }

    List<Facture> parseFactures(dynamic raw) {
      if (raw is! List) return const <Facture>[];
      return raw
          .whereType<Map>()
          .map((item) => Facture.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    }

    return TransporteurStatsSnapshot(
      transporteurId: (map['transporteurId'] ?? '').toString(),
      cachedAt:
          DateTime.tryParse((map['cachedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      totalEnLigne: toDouble(map['totalEnLigne']),
      totalHorsLigne: toDouble(map['totalHorsLigne']),
      pourcentageParSousZone: parsePercentages(map['pourcentageParSousZone']),
      commandesLivrees: parseCommandes(map['commandesLivrees']),
      factures: parseFactures(map['factures']),
    );
  }

  factory TransporteurStatsSnapshot.fromJson(String source) {
    return TransporteurStatsSnapshot.fromMap(
      json.decode(source) as Map<String, dynamic>,
    );
  }
}
