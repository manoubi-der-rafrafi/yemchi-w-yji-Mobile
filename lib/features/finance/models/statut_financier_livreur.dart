class StatutFinancierLivreur {
  const StatutFinancierLivreur({
    required this.configurationActive,
    required this.bloque,
    required this.detteNette,
    required this.montantBlocage,
    required this.pourcentageReglement,
    required this.paiementMinimum,
    required this.paiementRestant,
    required this.cibleDette,
    required this.message,
  });

  final bool configurationActive;
  final bool bloque;
  final double detteNette;
  final double montantBlocage;
  final double pourcentageReglement;
  final double paiementMinimum;
  final double paiementRestant;
  final double cibleDette;
  final String message;

  factory StatutFinancierLivreur.fromMap(Map<String, dynamic> map) {
    double number(String key) {
      final value = map[key];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return StatutFinancierLivreur(
      configurationActive: map['configurationActive'] == true,
      bloque: map['bloque'] == true,
      detteNette: number('detteNette'),
      montantBlocage: number('montantBlocage'),
      pourcentageReglement: number('pourcentageReglement'),
      paiementMinimum: number('paiementMinimum'),
      paiementRestant: number('paiementRestant'),
      cibleDette: number('cibleDette'),
      message: map['message']?.toString() ?? '',
    );
  }
}
