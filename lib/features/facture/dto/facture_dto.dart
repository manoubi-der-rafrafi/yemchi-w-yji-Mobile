import 'package:yemchi_wyji/core/models/facture.dart';

/// FactureDto : classe de transfert entre l'API et le modele Flutter.
class FactureDto {
  final String? id;
  final double? montant;
  final String? dateTimle;
  final String? image;
  final String? idLivreur;
  final FactureType? type;
  final FactureConfirmation? confirmer;

  const FactureDto({
    this.id,
    this.montant,
    this.dateTimle,
    this.image,
    this.idLivreur,
    this.type,
    this.confirmer,
  });

  Facture toModel() {
    return Facture(
      id: id ?? '',
      montant: montant ?? 0.0,
      dateTimle: dateTimle ?? '',
      image: image,
      idLivreur: idLivreur ?? '',
      type: type ?? FactureType.entrepriseVerseLivreur,
      confirmer: confirmer ?? FactureConfirmation.nonTraiter,
    );
  }

  factory FactureDto.fromModel(Facture facture) {
    return FactureDto(
      id: facture.id,
      montant: facture.montant,
      dateTimle: facture.dateTimle,
      image: facture.image,
      idLivreur: facture.idLivreur,
      type: facture.type,
      confirmer: facture.confirmer,
    );
  }

  factory FactureDto.fromMap(Map<String, dynamic> map) {
    double? parseMontant(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      final s = value.toString().trim();
      if (s.isEmpty) return null;
      return double.tryParse(s.replaceAll(',', '.'));
    }

    return FactureDto(
      id: map['_id']?.toString() ?? map['id']?.toString(),
      montant: parseMontant(map['montant']),
      dateTimle: (map['dateTimle'] ?? map['dateTime'])?.toString(),
      image: map['image'] as String?,
      idLivreur:
          (map['id_livreur'] ?? map['idLivreur'] ?? '').toString(),
      type: FactureTypeX.fromValue(map['type']?.toString()),
      confirmer: FactureConfirmationX.fromDynamic(map['confirmer']),
    );
  }

  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'montant': montant,
      'dateTimle': dateTimle,
      'image': image,
      'id_livreur': idLivreur,
      'type': type?.value,
      'confirmer': confirmer?.value,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }

  @override
  String toString() {
    return 'FactureDto(id: $id, montant: $montant, dateTimle: $dateTimle, idLivreur: $idLivreur, type: ${type?.value})';
  }
}
