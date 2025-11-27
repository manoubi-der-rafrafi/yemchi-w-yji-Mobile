import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/commande_details_page.dart';

class HistoriqueCommandesPage extends StatefulWidget {
  const HistoriqueCommandesPage({super.key});

  @override
  State<HistoriqueCommandesPage> createState() => _HistoriqueCommandesPageState();
}

class _HistoriqueCommandesPageState extends State<HistoriqueCommandesPage> {
  bool _isLoading = true;
  String? _error;
  List<Commande> _commandes = const <Commande>[];
  List<Commande> _filteredCommandes = const <Commande>[];
  double? _minPrice;
  double? _maxPrice;
  DateTimeRange? _dateRange;
  String? _selectedZone;

  bool get _hasFilters =>
      _minPrice != null ||
      _maxPrice != null ||
      _dateRange != null ||
      (_selectedZone != null && _selectedZone!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _fetchHistorique();
  }

  Future<void> _fetchHistorique() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthController>();
      final transporteurId = auth.currentUser.value?.id;
      if (transporteurId == null || transporteurId.isEmpty) {
        throw Exception('Utilisateur non connecte');
      }
      final service = CommandeService(Api());
      final data = await service.getCommandesByTransporteur(transporteurId);
      setState(() {
        _commandes = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final list = _commandes.where((commande) => _matchesFilters(commande)).toList();
    _filteredCommandes = list;
  }

  bool _matchesFilters(Commande commande) {
    final prix = commande.prix;
    if (_minPrice != null) {
      if (prix == null || prix < _minPrice!) return false;
    }
    if (_maxPrice != null) {
      if (prix == null || prix > _maxPrice!) return false;
    }

    if (_dateRange != null) {
      final date = commande.dateDemande ?? commande.dateDebut ?? commande.dateFin;
      if (date == null) return false;
      final start = DateUtils.dateOnly(_dateRange!.start);
      final end = DateUtils.dateOnly(_dateRange!.end);
      final target = DateUtils.dateOnly(date);
      if (target.isBefore(start) || target.isAfter(end)) {
        return false;
      }
    }

    if (_selectedZone != null && _selectedZone!.isNotEmpty) {
      final zone = _selectedZone!;
      final depart = commande.zonePrincipaleDepart ?? '';
      final arrivee = commande.zonePrincipaleArrivee ?? '';
      if (depart != zone && arrivee != zone) {
        return false;
      }
    }

    return true;
  }

  Future<void> _openFilters() async {
    final filters = await showModalBottomSheet<_HistoriqueFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        initialMinPrice: _minPrice,
        initialMaxPrice: _maxPrice,
        initialDateRange: _dateRange,
        initialZone: _selectedZone,
        zones: _availableZones,
      ),
    );
    if (filters == null) return;
    setState(() {
      _minPrice = filters.minPrice;
      _maxPrice = filters.maxPrice;
      _dateRange = filters.dateRange;
      _selectedZone = filters.zone;
      _applyFilters();
    });
  }

  List<String> get _availableZones {
    final set = <String>{};
    for (final c in _commandes) {
      if (c.zonePrincipaleDepart != null && c.zonePrincipaleDepart!.isNotEmpty) {
        set.add(c.zonePrincipaleDepart!);
      }
      if (c.zonePrincipaleArrivee != null && c.zonePrincipaleArrivee!.isNotEmpty) {
        set.add(c.zonePrincipaleArrivee!);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des commandes'),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: const Icon(Icons.search),
            color: _hasFilters ? theme.colorScheme.secondary : null,
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _HistoriqueError(
        error: _error!,
        onRetry: _fetchHistorique,
      );
    }
    if (_filteredCommandes.isEmpty) {
      return const _HistoriqueEmpty();
    }
    return _HistoriqueTable(
      commandes: _filteredCommandes,
      onDetails: (commande) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CommandeDetailsPage(commande: commande),
        ),
      ),
    );
  }
}

class _HistoriqueTable extends StatelessWidget {
  final List<Commande> commandes;
  final ValueChanged<Commande> onDetails;

  const _HistoriqueTable({
    required this.commandes,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalKm = commandes.fold<double>(
      0,
      (sum, c) => sum + (c.distanceKm ?? 0),
    );
    final totalPrix = commandes.fold<double>(
      0,
      (sum, c) => sum + (c.prix ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HistoriqueSummary(
          totalCommandes: commandes.length,
          totalKm: totalKm,
          totalPrix: totalPrix,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 720;
              if (isCompact) {
                return _HistoriqueCardList(
                  commandes: commandes,
                  onDetails: onDetails,
                );
              }
              return Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 28,
                      columns: const [
                        DataColumn(label: _ColumnHeader(icon: Icons.flight_takeoff, label: 'Depart')),
                        DataColumn(label: _ColumnHeader(icon: Icons.flag, label: 'Arrivee')),
                        DataColumn(label: _ColumnHeader(icon: Icons.route, label: 'Trajet')),
                        DataColumn(label: _ColumnHeader(icon: Icons.qr_code_2, label: 'Reception')),
                        DataColumn(label: _ColumnHeader(icon: Icons.payments, label: 'Prix')),
                        DataColumn(label: _ColumnHeader(icon: Icons.open_in_new, label: 'Actions')),
                      ],
                      rows: List<DataRow>.generate(commandes.length, (index) {
                        final commande = commandes[index];
                        final bool isEven = index.isEven;
                        return DataRow(
                          color: MaterialStateProperty.resolveWith(
                            (states) => isEven
                                ? theme.colorScheme.surfaceVariant.withOpacity(0.35)
                                : null,
                          ),
                          cells: [
                            DataCell(_ZoneCell(
                              title: commande.zonePrincipaleDepart,
                              subtitle: commande.sousZoneDepart,
                            )),
                            DataCell(_ZoneCell(
                              title: commande.zonePrincipaleArrivee,
                              subtitle: commande.sousZoneArrivee,
                            )),
                            DataCell(Text(
                              commande.distanceKm != null
                                  ? '${commande.distanceKm!.toStringAsFixed(1)} km'
                                  : '-',
                              style: theme.textTheme.bodyMedium,
                            )),
                            DataCell(
                              _QrStatusBadge(
                                scanned: commande.qrCodeReceptionScanne ?? false,
                              ),
                            ),
                            DataCell(Text(
                              commande.prix != null
                                  ? '${commande.prix!.toStringAsFixed(2)} DT'
                                  : '-',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                            DataCell(
                              FilledButton.tonalIcon(
                                onPressed: () => onDetails(commande),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Details'),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ZoneCell extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const _ZoneCell({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title ?? '-',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle ?? '-',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoriqueSummary extends StatelessWidget {
  final int totalCommandes;
  final double totalKm;
  final double totalPrix;

  const _HistoriqueSummary({
    required this.totalCommandes,
    required this.totalKm,
    required this.totalPrix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool wrap = constraints.maxWidth < 500;
            final children = [
              _SummaryTile(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Commandes',
                value: '$totalCommandes',
              ),
              _SummaryTile(
                icon: Icons.alt_route,
                label: 'Kilometres',
                value: '${totalKm.toStringAsFixed(1)} km',
              ),
              _SummaryTile(
                icon: Icons.attach_money,
                label: 'Revenus',
                value: '${totalPrix.toStringAsFixed(2)} DT',
              ),
            ];
            if (wrap) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 12,
                children: children,
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            );
          },
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoriqueCardList extends StatelessWidget {
  final List<Commande> commandes;
  final ValueChanged<Commande> onDetails;

  const _HistoriqueCardList({
    required this.commandes,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: commandes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final commande = commandes[index];
        return _CommandeCardTile(
          commande: commande,
          onDetails: () => onDetails(commande),
        );
      },
    );
  }
}

class _CommandeCardTile extends StatelessWidget {
  final Commande commande;
  final VoidCallback onDetails;

  const _CommandeCardTile({
    required this.commande,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flight_takeoff, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${commande.zonePrincipaleDepart ?? '-'} · ${commande.sousZoneDepart ?? '-'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.flag, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${commande.zonePrincipaleArrivee ?? '-'} · ${commande.sousZoneArrivee ?? '-'}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.route_outlined,
                  label: 'Trajet',
                  value: commande.distanceKm != null
                      ? '${commande.distanceKm!.toStringAsFixed(1)} km'
                      : 'N/A',
                ),
                _InfoChip(
                  icon: Icons.monetization_on_outlined,
                  label: 'Prix',
                  value: commande.prix != null
                      ? '${commande.prix!.toStringAsFixed(2)} DT'
                      : 'N/A',
                ),
                _InfoChip(
                  icon: Icons.qr_code_2,
                  label: 'Reception',
                  value: commande.qrCodeReceptionScanne == true ? 'Scannee' : 'Non scannee',
                ),
                if (commande.statut != null)
                  _InfoChip(
                    icon: Icons.event_available_outlined,
                    label: 'Statut',
                    value: commande.statut!,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onDetails,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label : ',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ColumnHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QrStatusBadge extends StatelessWidget {
  final bool scanned;

  const _QrStatusBadge({required this.scanned});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = scanned ? Colors.green : theme.colorScheme.error;
    final label = scanned ? 'Scannee' : 'Non scannee';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistoriqueFilters {
  final double? minPrice;
  final double? maxPrice;
  final DateTimeRange? dateRange;
  final String? zone;

  const _HistoriqueFilters({
    required this.minPrice,
    required this.maxPrice,
    required this.dateRange,
    required this.zone,
  });
}

class _FilterSheet extends StatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final DateTimeRange? initialDateRange;
  final String? initialZone;
  final List<String> zones;

  const _FilterSheet({
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialDateRange,
    required this.initialZone,
    required this.zones,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  DateTimeRange? _dateRange;
  String? _selectedZone;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: widget.initialMinPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialMaxPrice?.toString() ?? '',
    );
    _dateRange = widget.initialDateRange;
    _selectedZone = widget.initialZone;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtrer les commandes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix minimum',
                        prefixText: 'DT ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix maximum',
                        prefixText: 'DT ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Intervalle de dates',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.event),
                      label: Text(_dateRangeLabel),
                    ),
                  ),
                  if (_dateRange != null)
                    IconButton(
                      onPressed: () => setState(() => _dateRange = null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Effacer',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedZone?.isEmpty ?? true ? null : _selectedZone,
                decoration: const InputDecoration(
                  labelText: 'Zone principale',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Toutes les zones'),
                  ),
                  ...widget.zones.map(
                    (zone) => DropdownMenuItem(
                      value: zone,
                      child: Text(zone),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedZone = (value == null || value.isEmpty) ? null : value;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reinitialiser'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.check),
                    label: const Text('Appliquer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  String get _dateRangeLabel {
    if (_dateRange == null) return 'Selectionner';
    final start = _formatDate(_dateRange!.start);
    final end = _formatDate(_dateRange!.end);
    return '$start - $end';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _resetFilters() {
    setState(() {
      _minPriceController.clear();
      _maxPriceController.clear();
      _dateRange = null;
      _selectedZone = null;
    });
  }

  void _applyFilters() {
    final minPrice = double.tryParse(_minPriceController.text.trim());
    final maxPrice = double.tryParse(_maxPriceController.text.trim());
    Navigator.of(context).pop(
      _HistoriqueFilters(
        minPrice: minPrice,
        maxPrice: maxPrice,
        dateRange: _dateRange,
        zone: _selectedZone,
      ),
    );
  }
}

class _HistoriqueEmpty extends StatelessWidget {
  const _HistoriqueEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.black38),
          SizedBox(height: 8),
          Text(
            'Aucune commande trouvee',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Votre historique apparaitra ici une fois des courses terminees.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoriqueError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _HistoriqueError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger l\'historique.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}
