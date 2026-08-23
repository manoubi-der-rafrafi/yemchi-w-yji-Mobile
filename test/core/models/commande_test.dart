import 'package:flutter_test/flutter_test.dart';
import 'package:yemchi_wyji/core/models/commande.dart';

void main() {
  test('parse et affiche l identite d une commande B2C', () {
    final commande = Commande.fromJson({
      'id': 'commande-1',
      'sourceCommande': 'B2C',
      'partenaireId': 'partenaire-1',
      'externalBusinessId': 'maison-cerisette',
      'partenaireNom': 'Maison Cerisette',
      'partenaireLogoUrl': 'https://cdn.example.com/logo.png',
      'nomDepart': 'Ancien nom de depart',
    });

    expect(commande.isB2c, isTrue);
    expect(commande.partenaireDisplayName, 'Maison Cerisette');
    expect(commande.partenaireLogoUrl, 'https://cdn.example.com/logo.png');
  });

  test('utilise le nom de depart pour les anciennes commandes B2C', () {
    final commande = Commande.fromJson({
      'id': 'commande-ancienne',
      'sourceCommande': 'B2C',
      'nomDepart': 'Boutique historique',
    });

    expect(commande.partenaireDisplayName, 'Boutique historique');
  });
}
