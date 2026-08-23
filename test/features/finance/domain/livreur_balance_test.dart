import 'package:flutter_test/flutter_test.dart';
import 'package:yemchi_wyji/features/finance/domain/livreur_balance.dart';

void main() {
  test('un paiement accepte du livreur diminue sa dette', () {
    final avantPaiement = calculerSoldeNetLivreur(
      creditEnLigne: 33.93,
      montantAReverser: 1914.19,
      paiementsLivreurAcceptes: 0,
      versementsEntrepriseAcceptes: 0,
    );
    final apresPaiement = calculerSoldeNetLivreur(
      creditEnLigne: 33.93,
      montantAReverser: 1914.19,
      paiementsLivreurAcceptes: 500,
      versementsEntrepriseAcceptes: 0,
    );

    expect(avantPaiement, closeTo(-1880.26, 0.001));
    expect(apresPaiement, closeTo(-1380.26, 0.001));
    expect(apresPaiement.abs(), lessThan(avantPaiement.abs()));
  });

  test('un versement de entreprise diminue son credit envers le livreur', () {
    final solde = calculerSoldeNetLivreur(
      creditEnLigne: 100,
      montantAReverser: 0,
      paiementsLivreurAcceptes: 0,
      versementsEntrepriseAcceptes: 40,
    );

    expect(solde, 60);
  });
}
