import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/produit.dart';

class CommandeProduitsResponse {
  final Commande commande;
  final List<Produit> produits;

  const CommandeProduitsResponse({
    required this.commande,
    required this.produits,
  });

  factory CommandeProduitsResponse.fromJson(Map<String, dynamic> json) {
    final rawProduits = json['produits'];

    return CommandeProduitsResponse(
      commande: Commande.fromJson(
        (json['commande'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      produits: rawProduits is List
          ? rawProduits
              .whereType<Map>()
              .map(
                (item) => Produit.fromMap(item.cast<String, dynamic>()),
              )
              .toList()
          : const <Produit>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commande': commande.toJson(),
      'produits': produits.map((produit) => produit.toMap()).toList(),
    };
  }
}
