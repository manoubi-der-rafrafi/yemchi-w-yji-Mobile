class Commande {
  final String id;
  final String? clientId;
  final String? statut;

  Commande({
    required this.id,
    this.clientId,
    this.statut,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'].toString(),
      clientId: json['client_id'] ?? json['clientId'],
      statut: json['statut'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'statut': statut,
  };
}
