import 'dart:convert';

/// Modele Produit pour le front Flutter.
/// Aligne sur le backend Spring Boot (MongoDB).
class Produit {
  final String id;

  // Metadonnees
  final String? nom;
  final String? type;

  // Medias
  final String? image1;
  final String? image2;
  final String? image3;

  // Prix (BigDecimal cote Java) represente ici en double
  final double? prix;

  // Quantite commandee (optionnelle)
  final int? quantite;
  final bool affecter;
  final int? quantiteAffecter;

  // Lien vers la commande associee
  final String? commandeId;

  const Produit({
    required this.id,
    this.nom,
    this.type,
    this.image1,
    this.image2,
    this.image3,
    this.prix,
    this.quantite,
    this.affecter = false,
    this.quantiteAffecter,
    this.commandeId,
  });

  Produit copyWith({
    String? id,
    String? nom,
    String? type,
    String? image1,
    String? image2,
    String? image3,
    double? prix,
    int? quantite,
    bool? affecter,
    int? quantiteAffecter,
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
      quantite: quantite ?? this.quantite,
      affecter: affecter ?? this.affecter,
      quantiteAffecter: quantiteAffecter ?? this.quantiteAffecter,
      commandeId: commandeId ?? this.commandeId,
    );
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    final dynamic rawId = map['_id'] ?? map['id'];
    final String id = rawId != null ? rawId.toString() : '';

    double? parsePrix(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      final s = value.toString().trim();
      if (s.isEmpty) return null;
      return double.tryParse(s.replaceAll(',', '.'));
    }

    int? parseQuantite(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      final s = value.toString().trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }

    return Produit(
      id: id,
      nom: map['nom'] as String?,
      type: map['type'] as String?,
      image1: map['image1'] as String?,
      image2: map['image2'] as String?,
      image3: map['image3'] as String?,
      prix: parsePrix(map['prix']),
      quantite: parseQuantite(map['quantite'] ?? map['quantity']),
      affecter: map['affecter'] as bool? ?? false,
      quantiteAffecter: parseQuantite(map['quantiteAffecter']),
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
      'quantite': quantite,
      'affecter': affecter,
      'quantiteAffecter': quantiteAffecter,
      'commandeId': commandeId,
    };
  }

  factory Produit.fromJson(String source) =>
      Produit.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson({bool includeId = true}) =>
      json.encode(toMap(includeId: includeId));

  @override
  String toString() {
    return 'Produit(id: $id, nom: $nom, type: $type, prix: $prix, quantite: $quantite, affecter: $affecter, quantiteAffecter: $quantiteAffecter, commandeId: $commandeId)';
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
        other.quantite == quantite &&
        other.affecter == affecter &&
        other.quantiteAffecter == quantiteAffecter &&
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
        quantite,
        affecter,
        quantiteAffecter,
        commandeId,
      );
}
