class Produit {
  final String id;
  final String nom;
  final String type;
  final String image1;
  int quantite;

  Produit({
    required this.id,
    required this.nom,
    required this.type,
    required this.image1,
    required this.quantite,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'].toString(),
      nom: json['nom'],
      type: json['type'],
      image1: json['image1'],
      quantite: json['quantite'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'type': type,
    'image1': image1,
    'quantite': quantite,
  };
}
