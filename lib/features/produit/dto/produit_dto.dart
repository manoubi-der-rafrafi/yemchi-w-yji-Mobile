import 'package:yemchi_wyji/core/models/produit.dart';

/// ProduitDTO : classe de transfert entre l'API et le modele Flutter.
class ProduitDTO {
  final String? id;
  final String? nom;
  final String? type;
  final String? image1;
  final String? image2;
  final String? image3;
  final double? prix;
  final int? quantite;
  final String? commandeId;

  const ProduitDTO({
    this.id,
    this.nom,
    this.type,
    this.image1,
    this.image2,
    this.image3,
    this.prix,
    this.quantite,
    this.commandeId,
  });

  Produit toModel() {
    return Produit(
      id: id ?? '',
      nom: nom,
      type: type,
      image1: image1,
      image2: image2,
      image3: image3,
      prix: prix,
      quantite: quantite,
      commandeId: commandeId,
    );
  }

  factory ProduitDTO.fromModel(Produit produit) {
    return ProduitDTO(
      id: produit.id,
      nom: produit.nom,
      type: produit.type,
      image1: produit.image1,
      image2: produit.image2,
      image3: produit.image3,
      prix: produit.prix,
      quantite: produit.quantite,
      commandeId: produit.commandeId,
    );
  }

  factory ProduitDTO.fromMap(Map<String, dynamic> map) {
    double? parsePrix(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.'));
    }

    int? parseQuantite(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      final s = value.toString().trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }

    return ProduitDTO(
      id: map['_id']?.toString() ?? map['id']?.toString(),
      nom: map['nom'] as String?,
      type: map['type'] as String?,
      image1: map['image1'] as String?,
      image2: map['image2'] as String?,
      image3: map['image3'] as String?,
      prix: parsePrix(map['prix']),
      quantite: parseQuantite(map['quantite'] ?? map['quantity']),
      commandeId: map['commandeId'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'nom': nom,
      'type': type,
      'image1': image1,
      'image2': image2,
      'image3': image3,
      'prix': prix,
      'quantite': quantite,
      'commandeId': commandeId,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }

  @override
  String toString() {
    return 'ProduitDTO(id: $id, nom: $nom, type: $type, prix: $prix, quantite: $quantite)';
  }
}
