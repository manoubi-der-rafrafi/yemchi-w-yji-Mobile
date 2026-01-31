import 'dart:convert';

enum FactureType {
  entrepriseVerseLivreur,
  livreurVerseEntreprise,
}

extension FactureTypeX on FactureType {
  String get value {
    switch (this) {
      case FactureType.entrepriseVerseLivreur:
        return 'ENTREPRISE_VERSE_LIVREUR';
      case FactureType.livreurVerseEntreprise:
        return 'LIVREUR_VERSE_ENTREPRISE';
    }
  }

  static FactureType? fromValue(String? value) {
    switch (value) {
      case 'ENTREPRISE_VERSE_LIVREUR':
        return FactureType.entrepriseVerseLivreur;
      case 'LIVREUR_VERSE_ENTREPRISE':
        return FactureType.livreurVerseEntreprise;
      default:
        return null;
    }
  }
}

/// Modele Facture pour le front Flutter.
/// Aligne sur le backend (MongoDB/Mongoose).
class Facture {
  final String id;
  final double montant;
  final String dateTimle;
  final String? image;
  final String idLivreur;
  final FactureType type;
  final bool confirmer;

  const Facture({
    required this.id,
    required this.montant,
    required this.dateTimle,
    this.image,
    required this.idLivreur,
    required this.type,
    this.confirmer = false,
  });

  Facture copyWith({
    String? id,
    double? montant,
    String? dateTimle,
    String? image,
    String? idLivreur,
    FactureType? type,
    bool? confirmer,
  }) {
    return Facture(
      id: id ?? this.id,
      montant: montant ?? this.montant,
      dateTimle: dateTimle ?? this.dateTimle,
      image: image ?? this.image,
      idLivreur: idLivreur ?? this.idLivreur,
      type: type ?? this.type,
      confirmer: confirmer ?? this.confirmer,
    );
  }

  factory Facture.fromMap(Map<String, dynamic> map) {
    final dynamic rawId = map['_id'] ?? map['id'];
    final String id = rawId != null ? rawId.toString() : '';

    double parseMontant(dynamic value) {
      if (value is num) return value.toDouble();
      final s = value?.toString().trim() ?? '';
      return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
    }

    final String dateTimle =
        (map['dateTimle'] ?? map['dateTime'] ?? '').toString();
    final String idLivreur =
        (map['id_livreur'] ?? map['idLivreur'] ?? '').toString();
    final FactureType type =
        FactureTypeX.fromValue(map['type']?.toString()) ??
            FactureType.entrepriseVerseLivreur;
    final bool confirmer = map['confirmer'] == true;

    return Facture(
      id: id,
      montant: parseMontant(map['montant']),
      dateTimle: dateTimle,
      image: map['image'] as String?,
      idLivreur: idLivreur,
      type: type,
      confirmer: confirmer,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return <String, dynamic>{
      if (includeId) 'id': id,
      'montant': montant,
      'dateTimle': dateTimle,
      'image': image,
      'id_livreur': idLivreur,
      'type': type.value,
      'confirmer': confirmer,
    };
  }

  factory Facture.fromJson(String source) =>
      Facture.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson({bool includeId = true}) =>
      json.encode(toMap(includeId: includeId));

  @override
  String toString() {
    return 'Facture(id: $id, montant: $montant, dateTimle: $dateTimle, idLivreur: $idLivreur, type: ${type.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Facture &&
        other.id == id &&
        other.montant == montant &&
        other.dateTimle == dateTimle &&
        other.image == image &&
        other.idLivreur == idLivreur &&
        other.type == type &&
        other.confirmer == confirmer;
  }

  @override
  int get hashCode => Object.hash(
        id,
        montant,
        dateTimle,
        image,
        idLivreur,
        type,
        confirmer,
      );
}
