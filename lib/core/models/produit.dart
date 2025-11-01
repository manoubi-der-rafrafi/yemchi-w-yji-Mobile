// lib/core/models/produit.dart
import 'dart:convert';

/// Modèle Produit pour le front Flutter
/// Aligné sur le backend Spring Boot (MongoDB):
/// champs connus: id, nom, type, image1, image2, image3, prix(BigDecimal), commandeId
class Produit {
  // Identifiant MongoDB
  final String id;

  // Métadonnées
  final String? nom;
  final String? type;

  // Médias
  final String? image1;
  final String? image2;
  final String? image3;

  // Prix (BigDecimal côté Java) – on le représente en double ici
  // Astuce: si vous voulez une meilleure précision, utilisez int (centimes)
  // et convertissez à l'affichage.
  final double? prix;

  // Lien vers la commande associée
  final String? commandeId;

  const Produit({
    required this.id,
    this.nom,
    this.type,
    this.image1,
    this.image2,
    this.image3,
    this.prix,
    this.commandeId,
  });

  /// Copie immuable
  Produit copyWith({
    String? id,
    String? nom,
    String? type,
    String? image1,
    String? image2,
    String? image3,
    double? prix,
    String? commandeId,
  }) {
    return Produit(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      image1: image1 ?? this.image1,
      image2: image2 ?? this.image2,
      image3: image3 ?? this.image3,
      prix: prix ?? this.prix,
      commandeId: commandeId ?? this.commandeId,
    );
  }

  // =========================
  //        JSON / Map
  // =========================

  /// fromMap compatible avec JSON décodé
  factory Produit.fromMap(Map<String, dynamic> map) {
    // le champ id peut arriver sous la forme "_id" (Mongo) ou "id"
    final id = (map['_id'] ?? map['id']).toString();

    // prix peut être num, String ou null -> on uniformise en double?
    double? _parsePrix(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return double.tryParse(s.replaceAll(',', '.'));
    }

    return Produit(
      id: id,
      nom: map['nom'] as String?,
      type: map['type'] as String?,
      image1: map['image1'] as String?,
      image2: map['image2'] as String?,
      image3: map['image3'] as String?,
      prix: _parsePrix(map['prix']),
      commandeId: map['commandeId'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return <String, dynamic>{
      if (includeId) 'id': id,
      'nom': nom,
      'type': type,
      'image1': image1,
      'image2': image2,
      'image3': image3,
      'prix': prix,
      'commandeId': commandeId,
    };
  }

  factory Produit.fromJson(String source) =>
      Produit.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson({bool includeId = true}) => json.encode(toMap(includeId: includeId));

  // =========================
  //     Helpers & Equality
  // =========================

  @override
  String toString() {
    return 'Produit(id: '"$id"', nom: '"$nom"', type: '"$type"', prix: '"$prix"', commandeId: '"$commandeId"')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Produit &&
        other.id == id &&
        other.nom == nom &&
        other.type == type &&
        other.image1 == image1 &&
        other.image2 == image2 &&
        other.image3 == image3 &&
        other.prix == prix &&
        other.commandeId == commandeId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        nom,
        type,
        image1,
        image2,
        image3,
        prix,
        commandeId,
      );
}
