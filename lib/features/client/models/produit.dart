class Produit {
  final String id;
  final String? nom;
  final String? type;
  final String? matiere;
  final double? poids;
  final double? hauteur;
  final double? largeur;
  final double? profondeur;
  final bool? fragile;
  final String? fragileDetail;
  final String? image;
  final String? image1;
  final String? image2;
  final String? image3;
  final double? prixUnitaire;
  final double? prix;
  int quantite;
  final String? commandeId;

  Produit({
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
    this.quantite = 1,
    this.commandeId,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    bool? b(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      return v.toString().toLowerCase() == 'true';
    }

    String? cid(dynamic v) {
      if (v == null) return null;
      if (v is String) return v.isEmpty ? null : v;
      if (v is Map) return v['id']?.toString();
      return null;
    }

    final image1 = json['image1'] as String?;
    return Produit(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom'] as String?,
      type: json['type'] as String?,
      matiere: json['matiere'] as String?,
      poids: d(json['poids']),
      hauteur: d(json['hauteur']),
      largeur: d(json['largeur']),
      profondeur: d(json['profondeur']),
      fragile: b(json['fragile']),
      fragileDetail: json['fragileDetail'] as String?,
      image: json['image'] as String? ?? image1,
      image1: image1,
      image2: json['image2'] as String?,
      image3: json['image3'] as String?,
      prixUnitaire: d(json['prixUnitaire']),
      prix: d(json['prix']),
      quantite: (json['quantite'] ?? json['quantity'] ?? 1) is num
          ? (json['quantite'] ?? json['quantity'] ?? 1).toInt()
          : int.tryParse((json['quantite'] ?? json['quantity'] ?? '1').toString()) ?? 1,
      commandeId: cid(json['commandeId']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
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
