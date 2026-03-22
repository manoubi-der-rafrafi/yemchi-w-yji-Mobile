import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';
import 'package:yemchi_wyji/features/commande/dto/commande_produits_response.dart';
import 'package:yemchi_wyji/features/commande/dto/transporteur_panne_commandes_response.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/commande_produits_page.dart';

class TransporteurPanneDetailsPage extends StatefulWidget {
  const TransporteurPanneDetailsPage({
    super.key,
    required this.data,
  });

  final TransporteurPanneCommandesResponse data;

  @override
  State<TransporteurPanneDetailsPage> createState() =>
      _TransporteurPanneDetailsPageState();
}

class _TransporteurPanneDetailsPageState
    extends State<TransporteurPanneDetailsPage> {
  late TransporteurPanneCommandesResponse _data;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshData(silent: true);
    });
  }

  Future<void> _refreshData({bool silent = false}) async {
    if (_isRefreshing) return;
    if (!silent && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      _isRefreshing = true;
    }

    try {
      final service = CommandeService(context.read<Api>());
      final entries = await service.getTransporteursEnPanneAvecCommandes();
      final transporteurId = _data.transporteur.id;
      final refreshed = entries.cast<TransporteurPanneCommandesResponse?>().firstWhere(
            (entry) => entry?.transporteur.id == transporteurId,
            orElse: () => null,
          );
      if (!mounted) return;
      setState(() {
        _data = _sanitizeData(
          refreshed ??
              TransporteurPanneCommandesResponse(
                transporteur: _data.transporteur,
                commandes: const <CommandeProduitsResponse>[],
              ),
        );
      });
    } catch (_) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Impossible de rafraichir la liste des commandes.'),
          ),
        );
    } finally {
      _isRefreshing = false;
      if (!mounted || silent) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleData = _sanitizeData(_data);
    final transporteur = visibleData.transporteur;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transporteur en panne'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isRefreshing ? null : _refreshData,
                child: Text(
                  _isRefreshing ? 'Actualisation...' : 'Afficher accepter',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _TransporteurAvatar(
                      imageUrl: transporteur.image,
                      nom: transporteur.nom,
                      prenom: transporteur.prenom,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transporteur.nom?.trim().isNotEmpty == true
                                ? transporteur.nom!.trim()
                                : 'Nom non disponible',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transporteur.prenom?.trim().isNotEmpty == true
                                ? transporteur.prenom!.trim()
                                : 'Prenom non disponible',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transporteur.telephone?.trim().isNotEmpty == true
                                ? transporteur.telephone!.trim()
                                : 'Numero non disponible',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Commandes',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (visibleData.commandes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Toutes les commandes de cette liste ont deja ete prises ou ne sont plus disponibles.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...visibleData.commandes.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CommandePanneCard(
                    commandeEntry: entry,
                    transporteur: transporteur,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  TransporteurPanneCommandesResponse _sanitizeData(
    TransporteurPanneCommandesResponse input,
  ) {
    final visibleCommandes = input.commandes.where((entry) {
      final secoursId = entry.commande.transporteurSecoursId?.trim() ?? '';
      return secoursId.isEmpty;
    }).toList();
    return TransporteurPanneCommandesResponse(
      transporteur: input.transporteur,
      commandes: visibleCommandes,
    );
  }
}

class _CommandePanneCard extends StatelessWidget {
  const _CommandePanneCard({
    required this.commandeEntry,
    required this.transporteur,
  });

  final CommandeProduitsResponse commandeEntry;
  final TransporteurPanneInfo transporteur;

  String _modePaiementLabel(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'en_ligne':
        return 'En ligne';
      case 'depart':
        return 'Au depart';
      case 'arrivee':
        return 'A l arrivee';
      default:
        return 'Non precise';
    }
  }

  String _prixLabel(double? prix) {
    if (prix == null) return 'Non precise';
    final hasDecimals = prix % 1 != 0;
    return hasDecimals
        ? '${prix.toStringAsFixed(2)} TND'
        : '${prix.toStringAsFixed(0)} TND';
  }

  String _destinationState(Commande commande) {
    return commande.qrCodeDepartScanne == true
        ? 'En route vers l arrivee'
        : 'En route vers le depart';
  }

  String _displayRoute(String? zone, String? sousZone, String? fallback) {
    final z = (zone ?? '').trim();
    final sz = (sousZone ?? '').trim();
    final fb = (fallback ?? '').trim();
    if (z.isNotEmpty && sz.isNotEmpty) return '$z / $sz';
    if (z.isNotEmpty) return z;
    if (sz.isNotEmpty) return sz;
    if (fb.isNotEmpty) return fb;
    return 'Non precise';
  }

  @override
  Widget build(BuildContext context) {
    final commande = commandeEntry.commande;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _destinationState(commande),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E8E3E),
                  ),
            ),
            const SizedBox(height: 12),
            _InfoLine(
              label: 'Mode de payement',
              value: _modePaiementLabel(commande.modePaiement),
            ),
            _InfoLine(
              label: 'Depart',
              value: _displayRoute(
                commande.zonePrincipaleDepart,
                commande.sousZoneDepart,
                commande.localisationDepart,
              ),
            ),
            _InfoLine(
              label: 'Arrivee',
              value: _displayRoute(
                commande.zonePrincipaleArrivee,
                commande.sousZoneArrivee,
                commande.destination,
              ),
            ),
            _InfoLine(label: 'Prix', value: _prixLabel(commande.prix)),
            _InfoLine(
              label: 'Tel depart',
              value: commande.telDepart?.trim().isNotEmpty == true
                  ? commande.telDepart!
                  : 'Non precise',
            ),
            _InfoLine(
              label: 'Tel arrivee',
              value: commande.telArrivee?.trim().isNotEmpty == true
                  ? commande.telArrivee!
                  : 'Non precise',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CommandeProduitsPage(
                            commande: commande,
                            produits: commandeEntry.produits,
                          ),
                        ),
                      );
                    },
                    child: const Text('Detail'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop<_TransporteurPanneRouteSelection>(
                        _TransporteurPanneRouteSelection(
                          commande: commande,
                          transporteur: transporteur,
                        ),
                      );
                    },
                    child: const Text('Voir trajet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransporteurPanneRouteSelection {
  const _TransporteurPanneRouteSelection({
    required this.commande,
    required this.transporteur,
  });

  final Commande commande;
  final TransporteurPanneInfo transporteur;
}

class _TransporteurAvatar extends StatelessWidget {
  const _TransporteurAvatar({
    required this.imageUrl,
    required this.nom,
    required this.prenom,
  });

  final String? imageUrl;
  final String? nom;
  final String? prenom;

  @override
  Widget build(BuildContext context) {
    final initials = ((prenom ?? '').isNotEmpty ? prenom![0] : '') +
        ((nom ?? '').isNotEmpty ? nom![0] : '');
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(imageUrl!.trim()),
      );
    }
    return CircleAvatar(
      radius: 28,
      child: Text(initials.isEmpty ? '?' : initials.toUpperCase()),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
