import 'dart:convert';

import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/finance/models/statut_financier_livreur.dart';

class FinanceLivreurService {
  FinanceLivreurService(this._api);

  final Api _api;

  Future<StatutFinancierLivreur> getMonStatut() async {
    final response = await _api.get('/finance-livreurs/me');
    final decoded = json.decode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Statut financier invalide');
    }
    return StatutFinancierLivreur.fromMap(Map<String, dynamic>.from(decoded));
  }
}
