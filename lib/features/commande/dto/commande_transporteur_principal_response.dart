import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/produit.dart';

class CommandeTransporteurPrincipalResponse {
  final Commande commande;
  final List<Produit> produits;
  final TransporteurPrincipalInfo transporteur;

  const CommandeTransporteurPrincipalResponse({
    required this.commande,
    required this.produits,
    required this.transporteur,
  });

  factory CommandeTransporteurPrincipalResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawProduits = json['produits'];
    return CommandeTransporteurPrincipalResponse(
      commande: Commande.fromJson(
        (json['commande'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      produits: rawProduits is List
          ? rawProduits
              .whereType<Map>()
              .map((item) => Produit.fromMap(item.cast<String, dynamic>()))
              .toList()
          : const <Produit>[],
      transporteur: TransporteurPrincipalInfo.fromJson(
        (json['transporteur'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
    );
  }
}

class TransporteurPrincipalInfo {
  final String id;
  final String? nom;
  final String? prenom;
  final String? telephone;
  final String? image;
  final double? latitude;
  final double? longitude;

  const TransporteurPrincipalInfo({
    required this.id,
    this.nom,
    this.prenom,
    this.telephone,
    this.image,
    this.latitude,
    this.longitude,
  });

  factory TransporteurPrincipalInfo.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return TransporteurPrincipalInfo(
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
