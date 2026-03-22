class Commande {
  final String id;
  final String? clientId;
  final String? statut;
  final DateTime? dateConfirmer;

  Commande({
    required this.id,
    this.clientId,
    this.statut,
    this.dateConfirmer,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'].toString(),
      clientId: json['client_id'] ?? json['clientId'],
      statut: json['statut'],
      dateConfirmer: _toDate(json['dateConfirmer'] ?? json['date_confirmer']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'statut': statut,
    'dateConfirmer': dateConfirmer?.toIso8601String(),
  };

  static DateTime? _toDate(dynamic v) {
    if (v == null || (v is String && v.trim().isEmpty)) return null;
    return DateTime.tryParse(v.toString());
  }
}
