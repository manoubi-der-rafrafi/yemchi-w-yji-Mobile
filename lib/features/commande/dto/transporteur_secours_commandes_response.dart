import 'package:yemchi_wyji/features/commande/dto/commande_produits_response.dart';

class TransporteurSecoursCommandesResponse {
  final TransporteurSecoursInfo transporteurSecours;
  final List<CommandeProduitsResponse> commandes;

  const TransporteurSecoursCommandesResponse({
    required this.transporteurSecours,
    required this.commandes,
  });

  factory TransporteurSecoursCommandesResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawCommandes = json['commandes'];

    return TransporteurSecoursCommandesResponse(
      transporteurSecours: TransporteurSecoursInfo.fromJson(
        (json['transporteurSecours'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      commandes: rawCommandes is List
          ? rawCommandes
              .whereType<Map>()
              .map(
                (item) => CommandeProduitsResponse.fromJson(
                  item.cast<String, dynamic>(),
                ),
              )
              .toList()
          : const <CommandeProduitsResponse>[],
    );
  }
}

class TransporteurSecoursInfo {
  final String id;
  final String? nom;
  final String? prenom;
  final String? telephone;
  final String? image;
  final double? latitude;
  final double? longitude;

  const TransporteurSecoursInfo({
    required this.id,
    this.nom,
    this.prenom,
    this.telephone,
    this.image,
    this.latitude,
    this.longitude,
  });

  factory TransporteurSecoursInfo.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return TransporteurSecoursInfo(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      telephone: json['telephone'] as String?,
      image: json['image'] as String?,
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
    );
  }
}
