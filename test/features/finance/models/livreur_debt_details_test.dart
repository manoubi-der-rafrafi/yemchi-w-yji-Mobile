import 'package:flutter_test/flutter_test.dart';
import 'package:yemchi_wyji/features/finance/models/livreur_debt_details.dart';

void main() {
  test('decode le detail des dettes et des affectations', () {
    final details = LivreurDebtDetails.fromMap({
      'produitsB2cAPayer': 0,
      'coursesAPayer': 12,
      'detteBrute': 12,
      'creditEnLigneDisponible': 0,
      'detteNette': 12,
      'creditLivreur': 0,
      'paiementsEnAttente': 25,
      'commandes': [
        {
          'commandeId': 'c2',
          'externalOrderId': 'EXT-c2',
          'montantInitial': 32,
          'montantPaye': 20,
          'resteAPayer': 12,
          'statutFinancier': 'PARTIELLE',
          'lignes': [
            {
              'ligneId': 'course:c2',
              'type': 'PART_SOCIETE_COURSE',
              'nom': 'Part societe de la course',
              'quantite': 1,
              'prixUnitaire': 22,
              'montantInitial': 22,
              'montantPaye': 10,
              'resteAPayer': 12,
            },
          ],
        },
      ],
      'paiements': [
        {
          'factureId': 'f2',
          'montant': 120,
          'montantAffecte': 120,
          'affectations': [
            {'commandeId': 'c2', 'libelle': 'Part societe', 'montant': 10},
          ],
        },
      ],
    });

    expect(details.detteNette, 12);
    expect(details.paiementsEnAttente, 25);
    expect(details.commandes.single.resteAPayer, 12);
    expect(details.commandes.single.lignes.single.type, 'PART_SOCIETE_COURSE');
    expect(details.paiements.single.affectations.single.commandeId, 'c2');
  });
}
