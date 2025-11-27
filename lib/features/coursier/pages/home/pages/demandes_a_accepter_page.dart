import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';

import 'package:yemchi_wyji/features/coursier/pages/home/controllers/home_controller.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/widgets/commande_details_sheet.dart';

class DemandesAAccepterPage extends StatefulWidget {
  const DemandesAAccepterPage({super.key});

  @override
  State<DemandesAAccepterPage> createState() => _DemandesAAccepterPageState();
}

class _DemandesAAccepterPageState extends State<DemandesAAccepterPage> {
  final Map<String, Future<Utilisateur?>> _clientFutures = {};
  final Set<SousZone> _selectedDepartSousZones = <SousZone>{};
  final Set<SousZone> _selectedArriveeSousZones = <SousZone>{};
  List<Commande>? _filteredCommandes;
  bool _isFilterLoading = false;

  Future<Utilisateur?>? _futureForClient(String? clientId) {
    if (clientId == null || clientId.trim().isEmpty) return null;
    return _clientFutures.putIfAbsent(
      clientId,
      () async {
        try {
          return await context.read<AuthUserService>().getById(clientId);
        } catch (_) {
          return null;
        }
      },
    );
  }

  Future<void> _refresh(HomeController home) async {
    final zone = home.currentZone;
    if (zone == null || zone.isEmpty) return;
    await home.refreshByZone(zone, silent: true);
    if (_selectedDepartSousZones.isEmpty && _selectedArriveeSousZones.isEmpty) {
      if (mounted) {
        setState(() => _filteredCommandes = null);
      }
    } else {
      await _applySousZoneFilter();
    }
  }

  bool _hasSpecificSelection(Set<SousZone> zones) {
    return zones.isNotEmpty && zones.length < SousZone.values.length;
  }

  List<String>? _serializeSousZones(
    Set<SousZone> zones, {
    required bool forceAll,
  }) {
    if (_hasSpecificSelection(zones)) {
      return zones.map((e) => e.name).toList();
    }
    if (forceAll) {
      return SousZone.values.map((e) => e.name).toList();
    }
    return null;
  }

  Future<void> _applySousZoneFilter() async {
    final bool departSpecific = _hasSpecificSelection(_selectedDepartSousZones);
    final bool arriveeSpecific = _hasSpecificSelection(_selectedArriveeSousZones);

    final departPayload = _serializeSousZones(
      _selectedDepartSousZones,
      forceAll: !departSpecific && arriveeSpecific,
    );
    final arriveePayload = _serializeSousZones(
      _selectedArriveeSousZones,
      forceAll: !arriveeSpecific && departSpecific,
    );

    if (departPayload == null && arriveePayload == null) {
      if (mounted) {
        setState(() {
          _filteredCommandes = null;
          _isFilterLoading = false;
        });
      }
      return;
    }

    setState(() => _isFilterLoading = true);
    try {
      final api = context.read<Api>();
      final service = CommandeService(api);
      final commandes = await service.getBySousZones(
        sousZonesDepart: departPayload,
        sousZonesArrivee: arriveePayload,
      );
      if (!mounted) return;
      setState(() => _filteredCommandes = commandes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur filtre sous-zone: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isFilterLoading = false);
      }
    }
  }

  void _onDepartSousZonesChanged(Set<SousZone> values) {
    setState(() {
      _selectedDepartSousZones
        ..clear()
        ..addAll(values);
    });
    _applySousZoneFilter();
  }

  void _onArriveeSousZonesChanged(Set<SousZone> values) {
    setState(() {
      _selectedArriveeSousZones
        ..clear()
        ..addAll(values);
    });
    _applySousZoneFilter();
  }

  void _clearFilters() {
    if (_selectedDepartSousZones.isEmpty && _selectedArriveeSousZones.isEmpty) {
      return;
    }
    setState(() {
      _selectedDepartSousZones.clear();
      _selectedArriveeSousZones.clear();
      _filteredCommandes = null;
    });
  }

  Future<void> _showCommandeDetails(Commande commande) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => CommandeDetailsSheet(
        commande: commande,
        isMine: false,
      ),
    );
    if (!mounted) return;
    await _refresh(context.read<HomeController>());
  }

  void _viewTrajet(Commande commande) {
    final home = context.read<HomeController>();
    home.selectCommande(commande);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final commandes = _filteredCommandes ?? home.commandes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes a accepter'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(home),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: commandes.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SousZoneFilters(
                    selectedDepart: _selectedDepartSousZones,
                    selectedArrivee: _selectedArriveeSousZones,
                    onDepartChanged: _onDepartSousZonesChanged,
                    onArriveeChanged: _onArriveeSousZonesChanged,
                    onClear: _clearFilters,
                  ),
                  if (_isFilterLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (commandes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Aucune commande a afficher pour le moment.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              );
            }
            final commande = commandes[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DemandeCommandeCard(
                commande: commande,
                clientFuture: _futureForClient(commande.clientId),
                onDetails: () => _showCommandeDetails(commande),
                onVoirTrajet: () => _viewTrajet(commande),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DemandeCommandeCard extends StatelessWidget {
  final Commande commande;
  final Future<Utilisateur?>? clientFuture;
  final VoidCallback onDetails;
  final VoidCallback onVoirTrajet;

  const _DemandeCommandeCard({
    required this.commande,
    required this.clientFuture,
    required this.onDetails,
    required this.onVoirTrajet,
  });

  Color _cardBackground() => const Color(0xFFE6F4EA);

  String _modePaiementLabel(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    switch (normalized) {
      case 'en_ligne':
        return 'paye';
      case 'depart':
        return 'depare';
      case 'arrivee':
        return 'arriver';
      default:
        return 'Mode inconnu';
    }
  }

  Color _modePaiementColor(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    switch (normalized) {
      case 'en_ligne':
        return const Color(0xFF1E8E3E);
      case 'depart':
        return const Color(0xFFFB8C00);
      case 'arrivee':
        return const Color(0xFF1976D2);
      default:
        return Colors.grey;
    }
  }

  String _formatZone(String? zone, String? sousZone) {
    final z = (zone ?? '').trim();
    final sz = (sousZone ?? '').trim();
    if (z.isEmpty && sz.isEmpty) return 'Zone non precisee';
    if (z.isNotEmpty && sz.isNotEmpty) return '$z / $sz';
    return z.isNotEmpty ? z : sz;
  }

  String _formatPrice(double? price) {
    if (price == null) return 'Non defini';
    final showDecimals = price % 1 != 0;
    return '${showDecimals ? price.toStringAsFixed(2) : price.toStringAsFixed(0)} TND';
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return 'Distance inconnue';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String _phoneLabel(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? 'Non communique' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      color: _cardBackground(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClientHeader(
              commande: commande,
              future: clientFuture,
            ),
            const SizedBox(height: 8),
            _ModePaiementBadge(
              label: _modePaiementLabel(commande.modePaiement),
              color: _modePaiementColor(commande.modePaiement),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RouteRow(
                      label: 'Depart',
                      value: _formatZone(
                        commande.zonePrincipaleDepart,
                        commande.sousZoneDepart,
                      ),
                      icon: Icons.flag_circle_outlined,
                    ),
                    const SizedBox(height: 8),
                    _RouteRow(
                      label: 'Arrivee',
                      value: _formatZone(
                        commande.zonePrincipaleArrivee,
                        commande.sousZoneArrivee,
                      ),
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            label: 'Prix',
                            value: _formatPrice(commande.prix),
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                            label: 'Distance',
                            value: _formatDistance(commande.distanceKm),
                            icon: Icons.social_distance,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PhoneRow(
                      label: 'Tel depart',
                      value: _phoneLabel(commande.telDepart),
                    ),
                    const SizedBox(height: 6),
                    _PhoneRow(
                      label: 'Tel arrivee',
                      value: _phoneLabel(commande.telArrivee),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: onDetails,
                  child: const Text('Details'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onVoirTrajet,
                    child: const Text('Voir le trajet'),
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

class _ClientHeader extends StatelessWidget {
  final Commande commande;
  final Future<Utilisateur?>? future;

  const _ClientHeader({
    required this.commande,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return _ClientRow(
        user: null,
        isLoading: false,
        commande: commande,
      );
    }
    return FutureBuilder<Utilisateur?>(
      future: future,
      builder: (context, snapshot) {
        return _ClientRow(
          user: snapshot.data,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          commande: commande,
        );
      },
    );
  }
}

class _ClientRow extends StatelessWidget {
  final Utilisateur? user;
  final bool isLoading;
  final Commande commande;

  const _ClientRow({
    required this.user,
    required this.isLoading,
    required this.commande,
  });

  String _fallback(String? value, String placeholder) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? placeholder : clean;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = user?.image?.trim();
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundImage:
              (avatarImage != null && avatarImage.isNotEmpty) ? NetworkImage(avatarImage) : null,
          child: (avatarImage == null || avatarImage.isEmpty)
              ? (isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fallback(
                  user != null ? '${user!.prenom ?? ''} ${user!.nom ?? ''}'.trim() : '',
                  'Client inconnu',
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _fallback(user?.email, 'Email indisponible'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                _fallback(commande.instructions, 'Aucune instruction'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModePaiementBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ModePaiementBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Mode :',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RouteRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final String label;
  final String value;

  const _PhoneRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.phone, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SousZoneFilters extends StatelessWidget {
  final Set<SousZone> selectedDepart;
  final Set<SousZone> selectedArrivee;
  final ValueChanged<Set<SousZone>> onDepartChanged;
  final ValueChanged<Set<SousZone>> onArriveeChanged;
  final VoidCallback onClear;

  const _SousZoneFilters({
    required this.selectedDepart,
    required this.selectedArrivee,
    required this.onDepartChanged,
    required this.onArriveeChanged,
    required this.onClear,
  });

  static const Map<String, List<SousZone>> _zonesToSousZones = {
    'GRAND TUNIS': [
      SousZone.TUNIS_CENTRE,
      SousZone.ARIANA_NORD,
      SousZone.BEN_AROUS_SUD,
      SousZone.MANOUBA_OUEST,
    ],
    'COTIER NORD': [
      SousZone.BIZERTE_METRO,
      SousZone.NABEUL_HAMMAMET,
      SousZone.KELIBIA_MENZEL_TEMIME,
    ],
    'CENTRE EST': [
      SousZone.SOUSSE,
      SousZone.MONASTIR,
      SousZone.MAHDIA,
    ],
    'SFAX': [
      SousZone.SFAX,
    ],
    'SUD EST': [
      SousZone.GABES,
      SousZone.DJERBA_ZARZIS,
    ],
    'INTERIEUR': [
      SousZone.KAIROUAN,
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtrer par sous-zone',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: _MultiSelectSousZoneField(
                label: 'Depart',
                selected: selectedDepart,
                onChanged: onDepartChanged,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: _MultiSelectSousZoneField(
                label: 'Arrivee',
                selected: selectedArrivee,
                onChanged: onArriveeChanged,
              ),
            ),
          ],
        ),
        if (selectedDepart.isNotEmpty || selectedArrivee.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Reinitialiser'),
            ),
          ),
      ],
    );
  }
}

class _MultiSelectSousZoneField extends StatelessWidget {
  final String label;
  final Set<SousZone> selected;
  final ValueChanged<Set<SousZone>> onChanged;

  const _MultiSelectSousZoneField({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  String _selectionLabel() {
    if (selected.isEmpty || selected.length >= SousZone.values.length) {
      return 'Toutes sous-zones';
    }
    if (selected.length <= 2) {
      return selected.map((e) => e.name.replaceAll('_', ' ')).join(', ');
    }
    return '${selected.length} sous-zones selectionnees';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await showModalBottomSheet<Set<SousZone>>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _SousZoneSelectionSheet(
            title: label,
            initialSelection: selected,
          ),
        );
        if (result != null) {
          final normalized = result.length >= SousZone.values.length
              ? <SousZone>{}
              : result;
          onChanged(normalized);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          _selectionLabel(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SousZoneSelectionSheet extends StatefulWidget {
  final String title;
  final Set<SousZone> initialSelection;

  const _SousZoneSelectionSheet({
    required this.title,
    required this.initialSelection,
  });

  @override
  State<_SousZoneSelectionSheet> createState() =>
      _SousZoneSelectionSheetState();
}

class _SousZoneSelectionSheetState extends State<_SousZoneSelectionSheet> {
  late Set<SousZone> _selection;

  @override
  void initState() {
    super.initState();
    _selection = Set<SousZone>.from(widget.initialSelection);
  }

  void _toggle(SousZone zone, bool? checked) {
    setState(() {
      if (checked == true) {
        _selection.add(zone);
      } else {
        _selection.remove(zone);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _SousZoneFilters._zonesToSousZones.entries.toList();
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              Text(
                'Choisir les sous-zones ${widget.title.toLowerCase()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Text(
                            entry.key,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        ...entry.value.map(
                          (zone) => CheckboxListTile(
                            value: _selection.contains(zone),
                            onChanged: (checked) => _toggle(zone, checked),
                            title: Text(zone.name.replaceAll('_', ' ')),
                            dense: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _selection.clear());
                    },
                    child: const Text('Tout effacer'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pop(Set<SousZone>.from(_selection));
                    },
                    child: const Text('Valider'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
