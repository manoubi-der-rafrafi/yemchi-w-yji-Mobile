double _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

class LivreurDebtDetails {
  final double produitsB2cAPayer;
  final double coursesAPayer;
  final double detteBrute;
  final double creditEnLigneDisponible;
  final double detteNette;
  final double creditLivreur;
  final double paiementsEnAttente;
  final List<CommandeDetteLivreur> commandes;
  final List<PaiementDetailLivreur> paiements;

  const LivreurDebtDetails({
    required this.produitsB2cAPayer,
    required this.coursesAPayer,
    required this.detteBrute,
    required this.creditEnLigneDisponible,
    required this.detteNette,
    required this.creditLivreur,
    required this.paiementsEnAttente,
    required this.commandes,
    required this.paiements,
  });

  factory LivreurDebtDetails.fromMap(Map<String, dynamic> map) {
    return LivreurDebtDetails(
      produitsB2cAPayer: _asDouble(map['produitsB2cAPayer']),
      coursesAPayer: _asDouble(map['coursesAPayer']),
      detteBrute: _asDouble(map['detteBrute']),
      creditEnLigneDisponible: _asDouble(map['creditEnLigneDisponible']),
      detteNette: _asDouble(map['detteNette']),
      creditLivreur: _asDouble(map['creditLivreur']),
      paiementsEnAttente: _asDouble(map['paiementsEnAttente']),
      commandes:
          (map['commandes'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) => CommandeDetteLivreur.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
      paiements:
          (map['paiements'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) => PaiementDetailLivreur.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
    );
  }
}

class CommandeDetteLivreur {
  final String commandeId;
  final String? externalOrderId;
  final DateTime? dateLivraison;
  final double montantInitial;
  final double montantPaye;
  final double resteAPayer;
  final String statutFinancier;
  final List<LigneDetteLivreur> lignes;

  const CommandeDetteLivreur({
    required this.commandeId,
    required this.externalOrderId,
    required this.dateLivraison,
    required this.montantInitial,
    required this.montantPaye,
    required this.resteAPayer,
    required this.statutFinancier,
    required this.lignes,
  });

  factory CommandeDetteLivreur.fromMap(Map<String, dynamic> map) =>
      CommandeDetteLivreur(
        commandeId: '${map['commandeId'] ?? ''}',
        externalOrderId: map['externalOrderId']?.toString(),
        dateLivraison: DateTime.tryParse('${map['dateLivraison'] ?? ''}'),
        montantInitial: _asDouble(map['montantInitial']),
        montantPaye: _asDouble(map['montantPaye']),
        resteAPayer: _asDouble(map['resteAPayer']),
        statutFinancier: '${map['statutFinancier'] ?? 'NON_PAYEE'}',
        lignes:
            (map['lignes'] as List? ?? const [])
                .whereType<Map>()
                .map(
                  (item) => LigneDetteLivreur.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(),
      );
}

class LigneDetteLivreur {
  final String ligneId;
  final String type;
  final String nom;
  final int quantite;
  final double prixUnitaire;
  final double montantInitial;
  final double montantPaye;
  final double resteAPayer;

  const LigneDetteLivreur({
    required this.ligneId,
    required this.type,
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
    required this.montantInitial,
    required this.montantPaye,
    required this.resteAPayer,
  });

  factory LigneDetteLivreur.fromMap(Map<String, dynamic> map) =>
      LigneDetteLivreur(
        ligneId: '${map['ligneId'] ?? ''}',
        type: '${map['type'] ?? ''}',
        nom: '${map['nom'] ?? ''}',
        quantite: (map['quantite'] as num?)?.toInt() ?? 1,
        prixUnitaire: _asDouble(map['prixUnitaire']),
        montantInitial: _asDouble(map['montantInitial']),
        montantPaye: _asDouble(map['montantPaye']),
        resteAPayer: _asDouble(map['resteAPayer']),
      );
}

class PaiementDetailLivreur {
  final String factureId;
  final double montant;
  final double montantAffecte;
  final List<AffectationPaiementLivreur> affectations;

  const PaiementDetailLivreur({
    required this.factureId,
    required this.montant,
    required this.montantAffecte,
    required this.affectations,
  });

  factory PaiementDetailLivreur.fromMap(Map<String, dynamic> map) =>
      PaiementDetailLivreur(
        factureId: '${map['factureId'] ?? ''}',
        montant: _asDouble(map['montant']),
        montantAffecte: _asDouble(map['montantAffecte']),
        affectations:
            (map['affectations'] as List? ?? const [])
                .whereType<Map>()
                .map(
                  (item) => AffectationPaiementLivreur.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(),
      );
}

class AffectationPaiementLivreur {
  final String commandeId;
  final String libelle;
  final double montant;

  const AffectationPaiementLivreur({
    required this.commandeId,
    required this.libelle,
    required this.montant,
  });

  factory AffectationPaiementLivreur.fromMap(Map<String, dynamic> map) =>
      AffectationPaiementLivreur(
        commandeId: '${map['commandeId'] ?? ''}',
        libelle: '${map['libelle'] ?? ''}',
        montant: _asDouble(map['montant']),
      );
}
