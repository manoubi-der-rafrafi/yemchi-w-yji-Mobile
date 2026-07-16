import 'package:yemchi_wyji/features/commande/dto/commande_produits_response.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';

class TransporteurPanneCommandesResponse {
  final TransporteurPanneInfo transporteur;
  final List<CommandeProduitsResponse> commandes;

  const TransporteurPanneCommandesResponse({
    required this.transporteur,
    required this.commandes,
  });

  factory TransporteurPanneCommandesResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawCommandes = json['commandes'];

    return TransporteurPanneCommandesResponse(
      transporteur: TransporteurPanneInfo.fromJson(
        (json['transporteur'] as Map?)?.cast<String, dynamic>() ??
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

class TransporteurPanneInfo {
  final String id;
  final String? nom;
  final String? prenom;
  final String? image;
  final String? telephone;
  final double? latitude;
  final double? longitude;
  final EtatIncident etatIncident;

  const TransporteurPanneInfo({
    required this.id,
    this.nom,
    this.prenom,
    this.image,
    this.telephone,
    this.latitude,
    this.longitude,
    this.etatIncident = EtatIncident.PANNE,
  });

  factory TransporteurPanneInfo.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    EtatIncident toEtatIncident(dynamic value) {
      final raw = (value ?? '').toString().trim().toUpperCase();
      switch (raw) {
        case 'ACCIDENT':
          return EtatIncident.ACCIDENT;
        case 'PANNE':
          return EtatIncident.PANNE;
        case 'RIEN':
        default:
          return EtatIncident.RIEN;
      }
    }

    return TransporteurPanneInfo(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      image: json['image'] as String?,
      telephone: json['telephone'] as String?,
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      etatIncident: toEtatIncident(
        json['etatIncident'] ?? json['etat_incident'],
      ),
    );
  }
}
