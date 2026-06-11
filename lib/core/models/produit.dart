/// Modele Produit pour le front Flutter.
/// Aligne sur le backend Spring Boot (MongoDB).
class Produit {
  final String id;

  // Metadonnees
  final String? nom;
  final String? type;
  final String? matiere;

  // Dimensions & poids
  final double? poids;
  final double? hauteur;
  final double? largeur;
  final double? profondeur;

  // Fragile
  final bool? fragile;
  final String? fragileDetail;

  // Medias
  final String? image;   // alias image1, principal
  final String? image1;
  final String? image2;
  final String? image3;

  // Prix (BigDecimal cote Java) represente ici en double
  // Le backend attend prixUnitaire a la creation, renvoie prix dans la reponse.
  final double? prixUnitaire;
  final double? prix;

  // Quantite commandee
  final int? quantite;

  // Lien vers la commande associee
  final String? commandeId;

  const Produit({
    required this.id,
    this.nom,
    this.type,
    this.matiere,
    this.poids,
    this.hauteur,
    this.largeur,
    this.profondeur,
    this.fragile,
    this.fragileDetail,
    this.image,
    this.image1,
    this.image2,
    this.image3,
    this.prixUnitaire,
    this.prix,
    this.quantite,
    this.commandeId,
  });

  Produit copyWith({
    String? id,
    String? nom,
    String? type,
    String? matiere,
    double? poids,
    double? hauteur,
    double? largeur,
    double? profondeur,
    bool? fragile,
    String? fragileDetail,
    String? image,
    String? image1,
    String? image2,
    String? image3,
    double? prixUnitaire,
    double? prix,
    int? quantite,
    String? commandeId,
  }) {
    return Produit(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      matiere: matiere ?? this.matiere,
      poids: poids ?? this.poids,
      hauteur: hauteur ?? this.hauteur,
      largeur: largeur ?? this.largeur,
      profondeur: profondeur ?? this.profondeur,
      fragile: fragile ?? this.fragile,
      fragileDetail: fragileDetail ?? this.fragileDetail,
      image: image ?? this.image,
      image1: image1 ?? this.image1,
      image2: image2 ?? this.image2,
      image3: image3 ?? this.image3,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      prix: prix ?? this.prix,
      quantite: quantite ?? this.quantite,
      commandeId: commandeId ?? this.commandeId,
    );
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    final dynamic rawId = map['_id'] ?? map['id'];
    final String id = rawId != null ? rawId.toString() : '';

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      final s = value.toString().trim();
      if (s.isEmpty) return null;
      return double.tryParse(s.replaceAll(',', '.'));
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      final s = value.toString().trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }

    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      final s = value.toString().trim().toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
      return null;
    }

    // commandeId can be a plain string or an object {"id": "..."}
    String? parseCommandeId(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is Map) return value['id']?.toString();
      return null;
    }

    final image1 = map['image1'] as String?;
    final image = map['image'] as String? ?? image1;

    return Produit(
      id: id,
      nom: map['nom'] as String?,
      type: map['type'] as String?,
      matiere: map['matiere'] as String?,
      poids: parseDouble(map['poids']),
      hauteur: parseDouble(map['hauteur']),
      largeur: parseDouble(map['largeur']),
      profondeur: parseDouble(map['profondeur']),
      fragile: parseBool(map['fragile']),
      fragileDetail: map['fragileDetail'] as String?,
      image: image,
      image1: image1,
      image2: map['image2'] as String?,
      image3: map['image3'] as String?,
      prixUnitaire: parseDouble(map['prixUnitaire']),
      prix: parseDouble(map['prix']),
      quantite: parseInt(map['quantite'] ?? map['quantity']),
      commandeId: parseCommandeId(map['commandeId']),
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return <String, dynamic>{
      if (includeId) 'id': id,
      'nom': nom,
      'type': type,
      'matiere': matiere,
      'poids': poids,
      'hauteur': hauteur,
      'largeur': largeur,
      'profondeur': profondeur,
      'fragile': fragile,
      'fragileDetail': fragileDetail,
      'image': image,
      'image1': image1,
      'image2': image2,
      'image3': image3,
      'prixUnitaire': prixUnitaire,
      'prix': prix,
      'quantite': quantite,
      'commandeId': commandeId,
    };
  }

  factory Produit.fromJson(Map<String, dynamic> source) =>
      Produit.fromMap(source);

  Map<String, dynamic> toJson({bool includeId = true}) =>
      toMap(includeId: includeId);

  @override
  String toString() {
    return 'Produit(id: $id, nom: $nom, type: $type, poids: $poids, prix: $prix, quantite: $quantite, commandeId: $commandeId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Produit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
