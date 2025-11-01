// lib/features/produit/dto/produit_dto.dart

import 'package:yemchi_wyji/core/models/produit.dart';

/// ProduitDTO : classe de transfert entre l’API et le modèle Flutter.
/// Inspirée de commande_dto.dart — même logique.
class ProduitDTO {
  final String? id;
  final String? nom;
  final String? type;
  final String? image1;
  final String? image2;
  final String? image3;
  final double? prix;
  final String? commandeId;

  ProduitDTO({
    this.id,
    this.nom,
    this.type,
    this.image1,
    this.image2,
    this.image3,
    this.prix,
    this.commandeId,
  });

  /// Convertit le DTO en modèle métier Flutter
  Produit toModel() {
    return Produit(
      id: id ?? '',
      nom: nom,
      type: type,
      image1: image1,
      image2: image2,
      image3: image3,
      prix: prix,
      commandeId: commandeId,
    );
  }

  /// Crée un DTO à partir du modèle Flutter
  factory ProduitDTO.fromModel(Produit produit) {
    return ProduitDTO(
      id: produit.id,
      nom: produit.nom,
      type: produit.type,
      image1: produit.image1,
      image2: produit.image2,
      image3: produit.image3,
      prix: produit.prix,
      commandeId: produit.commandeId,
    );
  }

  /// Crée un DTO à partir d’une Map (JSON)
  factory ProduitDTO.fromMap(Map<String, dynamic> map) {
    double? _parsePrix(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(',', '.'));
    }

    return ProduitDTO(
      id: map['_id']?.toString() ?? map['id']?.toString(),
      nom: map['nom'],
      type: map['type'],
      image1: map['image1'],
      image2: map['image2'],
      image3: map['image3'],
      prix: _parsePrix(map['prix']),
      commandeId: map['commandeId'],
    );
  }

  /// Convertit en Map (pour envoi API)
  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = {
      'nom': nom,
      'type': type,
      'image1': image1,
      'image2': image2,
      'image3': image3,
      'prix': prix,
      'commandeId': commandeId,
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }

  @override
  String toString() {
    return 'ProduitDTO(id: $id, nom: $nom, type: $type, prix: $prix)';
  }
}
