import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/facture.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';
import 'package:yemchi_wyji/features/facture/data/facture_service.dart';

import 'transporteur_stats_snapshot.dart';

class TransporteurStatsService {
  TransporteurStatsService({
    CommandeService? commandeService,
    FactureService? factureService,
  }) : _commandeService = commandeService ?? CommandeService(Api()),
       _factureService = factureService ?? FactureService();

  final CommandeService _commandeService;
  final FactureService _factureService;

  Future<TransporteurStatsSnapshot> fetch(String transporteurId) async {
    final results = await Future.wait<Object>([
      _commandeService.getSommePrixLivreeEnLigneByTransporteur(transporteurId),
      _commandeService.getSommePrixLivreeHorsLigneByTransporteur(
        transporteurId,
      ),
      _commandeService.getPourcentageRevenuParSousZoneLivreeByTransporteur(
        transporteurId,
      ),
      _commandeService.getCommandesLivreesByTransporteur(transporteurId),
      _factureService.listByLivreurId(transporteurId),
    ]);

    return TransporteurStatsSnapshot(
      transporteurId: transporteurId,
      cachedAt: DateTime.now(),
      totalEnLigne: results[0] as double,
      totalHorsLigne: results[1] as double,
      pourcentageParSousZone: Map<String, double>.from(
        results[2] as Map<String, double>,
      ),
      commandesLivrees: List<Commande>.from(
        (results[3] as List).cast<Commande>(),
      ),
      factures: List<Facture>.from((results[4] as List).cast<Facture>()),
    );
  }
}
