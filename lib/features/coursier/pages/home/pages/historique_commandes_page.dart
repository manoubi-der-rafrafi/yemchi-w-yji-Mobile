import 'dart:math' as math;
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/facture.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/pages/commande_details_page.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/services/transporteur_stats_cache_service.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/services/transporteur_stats_service.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/services/transporteur_stats_snapshot.dart';
import 'package:yemchi_wyji/features/facture/data/facture_service.dart';

class HistoriqueCommandesPage extends StatefulWidget {
  const HistoriqueCommandesPage({super.key});

  @override
  State<HistoriqueCommandesPage> createState() =>
      _HistoriqueCommandesPageState();
}

class _HistoriqueCommandesPageState extends State<HistoriqueCommandesPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoadedData = false;
  String? _error;
  double _totalEnLigne = 0;
  double _totalHorsLigne = 0;
  double _montantVertEntreprise = 0;
  double _montantVertLivreur = 0;
  Map<String, double> _pourcentageParSousZone = {};
  List<Commande> _commandesLivrees = [];
  List<Facture> _factures = [];
  int? _selectedSousZoneIndex;
  int? _hoveredSousZoneIndex;
  String? _modePaiementFilter;
  DateTimeRange? _dateRange;
  FactureType? _factureTypeFilter;
  DateTimeRange? _factureDateRange;
  late final AnimationController _donutController;
  late final Animation<double> _donutAnim;
  final TransporteurStatsService _statsService = TransporteurStatsService();
  final TransporteurStatsCacheService _cacheService =
      TransporteurStatsCacheService();

  double get _diff =>
      (_totalHorsLigne - _totalEnLigne) * 0.5 -
      (_montantVertEntreprise - _montantVertLivreur);
  bool get _isCreditLivreur => _diff >= 0;
  double get _soldeLivreur => _diff.abs().clamp(0, 800);
  double get _totalRevenue => _totalEnLigne + _totalHorsLigne;

  @override
  void initState() {
    super.initState();
    _donutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _donutAnim = CurvedAnimation(
      parent: _donutController,
      curve: Curves.easeOutCubic,
    );
    _loadInitialData();
  }

  String? get _transporteurId =>
      context.read<AuthController>().currentUser.value?.id;

  Future<void> _loadInitialData() async {
    final transporteurId = _transporteurId;
    if (transporteurId == null || transporteurId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'Utilisateur non connecte';
        _isLoading = false;
      });
      return;
    }

    final cached = await _cacheService.read(transporteurId);
    if (!mounted) return;

    if (cached != null) {
      setState(() {
        _applySnapshot(cached);
        _isLoading = false;
        _error = null;
      });
      _donutController.forward(from: 0);
      unawaited(_fetchGains(silent: true));
      return;
    }

    await _fetchGains();
  }

  void _applySnapshot(TransporteurStatsSnapshot snapshot) {
    _totalEnLigne = snapshot.totalEnLigne;
    _totalHorsLigne = snapshot.totalHorsLigne;
    _pourcentageParSousZone = Map<String, double>.from(
      snapshot.pourcentageParSousZone,
    );
    _commandesLivrees = List<Commande>.from(snapshot.commandesLivrees);
    _factures = List<Facture>.from(snapshot.factures);
    final facturesConfirmees = _factures.where(
      (f) => f.confirmer == FactureConfirmation.acceter,
    );
    _montantVertEntreprise = facturesConfirmees
        .where((f) => f.type == FactureType.livreurVerseEntreprise)
        .fold<double>(0, (sum, f) => sum + f.montant);
    _montantVertLivreur = facturesConfirmees
        .where((f) => f.type == FactureType.entrepriseVerseLivreur)
        .fold<double>(0, (sum, f) => sum + f.montant);
    _hasLoadedData = true;
  }

  Future<void> _fetchGains({bool silent = false}) async {
    final transporteurId = _transporteurId;
    if (transporteurId == null || transporteurId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'Utilisateur non connecte';
        _isLoading = false;
        _isRefreshing = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _error = null;
        if (!_hasLoadedData && !silent) {
          _isLoading = true;
        } else {
          _isRefreshing = true;
        }
      });
    }

    try {
      final snapshot = await _statsService.fetch(transporteurId);
      await _cacheService.write(snapshot);
      if (!mounted) return;
      setState(() {
        _applySnapshot(snapshot);
        _isLoading = false;
        _isRefreshing = false;
      });
      _donutController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!_hasLoadedData) {
          _error = e.toString();
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _donutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sousZoneBreakdown = _buildSousZoneBreakdown();
    final hasSousZoneData = sousZoneBreakdown.any((z) => z.percent > 0.01);
    final activeSousZoneIndex = _selectedSousZoneIndex ?? _hoveredSousZoneIndex;
    final activeZoneLabel =
        (activeSousZoneIndex != null &&
                activeSousZoneIndex >= 0 &&
                activeSousZoneIndex < sousZoneBreakdown.length)
            ? sousZoneBreakdown[activeSousZoneIndex].name
            : null;
    final availableModes = _buildModePaiementOptions();
    final selectedMode = _modePaiementFilter ?? 'Tous';
    final filteredLivrees = _filteredCommandes(
      activeZoneLabel,
      selectedMode,
      _dateRange,
    );
    final gaugeRatio = (_soldeLivreur / 800).clamp(0.0, 1.0);
    final gaugeColor =
        Color.lerp(const Color(0xFF2E7D32), Colors.red, gaugeRatio) ??
        theme.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des commandes'),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _fetchGains,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _GainsError(error: _error!, onRetry: _fetchGains)
                : Stack(
                  children: [
                    ListView(
                      children: [
                        Card(
                          elevation: 0.5,
                          color: const Color(0xFFF7F7F2),
                          surfaceTintColor: Colors.transparent,
                          shadowColor: Colors.black.withOpacity(0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MiniStatCard(
                                        label: 'Total revenue',
                                        value: _formatMoney(_totalRevenue),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _MiniStatCard(
                                        label: 'Total enligne',
                                        value: _formatMoney(_totalEnLigne),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _MiniStatCard(
                                        label: 'Total non enligne',
                                        value: _formatMoney(_totalHorsLigne),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F7F0),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.06),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Revenu par sous-zone',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF1F1F1F,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE9EFE6),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              'Ce mois',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFF5E6B62,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      hasSousZoneData
                                          ? AnimatedBuilder(
                                            animation: _donutAnim,
                                            builder: (context, _) {
                                              return _SousZoneRingWithMetrics(
                                                segments: sousZoneBreakdown,
                                                activeIndex:
                                                    activeSousZoneIndex,
                                                progress: _donutAnim.value,
                                                onSegmentTap: (index) {
                                                  setState(() {
                                                    _selectedSousZoneIndex =
                                                        index;
                                                  });
                                                },
                                                onSegmentHover: (index) {
                                                  setState(() {
                                                    _hoveredSousZoneIndex =
                                                        index;
                                                  });
                                                },
                                                onHoverExit: () {
                                                  setState(() {
                                                    _hoveredSousZoneIndex =
                                                        null;
                                                  });
                                                },
                                              );
                                            },
                                          )
                                          : Text(
                                            'Aucune donnee disponible.',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF6B776E,
                                                  ),
                                                ),
                                          ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _CommandesLivreesSection(
                                  commandes: filteredLivrees,
                                  modes: availableModes,
                                  selectedMode: selectedMode,
                                  onModeChanged: (value) {
                                    setState(() {
                                      _modePaiementFilter =
                                          value == 'Tous' ? null : value;
                                    });
                                  },
                                  dateRange: _dateRange,
                                  onPickDateRange: _pickDateRange,
                                  onClearDateRange: () {
                                    setState(() {
                                      _dateRange = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isRefreshing)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
                ),
      ),
    );
  }

  String _formatMoney(double value) => '${value.toStringAsFixed(2)} DT';

  List<_ZoneBreakdown> _buildSousZoneBreakdown() {
    const tunisColor = Color(0xFF0F9A8A);
    const bejaColor = Color(0xFFF0AE72);

    final tunisPercent = _percentForLabel(const ['TUNIS']);
    final bejaPercent = _percentForLabel(const ['BEJA', 'BÉJA']);
    final total = _totalRevenue;

    return [
      _ZoneBreakdown(
        name: 'TUNIS',
        percent: tunisPercent,
        value: total * (tunisPercent / 100),
        color: tunisColor,
      ),
      _ZoneBreakdown(
        name: 'BÉJA',
        percent: bejaPercent,
        value: total * (bejaPercent / 100),
        color: bejaColor,
      ),
    ];
  }

  double _percentForLabel(List<String> aliases) {
    for (final entry in _pourcentageParSousZone.entries) {
      final upper = entry.key.toUpperCase();
      if (aliases.any((alias) => upper.contains(alias))) {
        return entry.value.clamp(0, 100);
      }
    }
    return 0;
  }

  List<String> _buildModePaiementOptions() {
    return const ['Tous', 'EN_LIGNE', 'HORS_LIGNE'];
  }

  List<Facture> _filteredFactures() {
    return _factures.where((facture) {
      if (_factureTypeFilter != null && facture.type != _factureTypeFilter) {
        return false;
      }
      if (_factureDateRange != null) {
        final date = _parseDateTime(facture.dateTimle);
        if (date == null) return false;
        final dateOnly = DateTime(date.year, date.month, date.day);
        final start = DateTime(
          _factureDateRange!.start.year,
          _factureDateRange!.start.month,
          _factureDateRange!.start.day,
        );
        final end = DateTime(
          _factureDateRange!.end.year,
          _factureDateRange!.end.month,
          _factureDateRange!.end.day,
        );
        if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<Commande> _filteredCommandes(
    String? zoneLabel,
    String selectedMode,
    DateTimeRange? dateRange,
  ) {
    final zone = _normalizeZone(zoneLabel);
    return _commandesLivrees.where((commande) {
      if (selectedMode != 'Tous') {
        final mode = _normalizeModePaiement(commande.modePaiement);
        if (mode != selectedMode) return false;
      }
      if (dateRange != null) {
        final date = commande.dateDemande;
        if (date == null) return false;
        final dateOnly = DateTime(date.year, date.month, date.day);
        final start = DateTime(
          dateRange.start.year,
          dateRange.start.month,
          dateRange.start.day,
        );
        final end = DateTime(
          dateRange.end.year,
          dateRange.end.month,
          dateRange.end.day,
        );
        if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) {
          return false;
        }
      }
      if (zone != null) {
        final depart = _normalizeZone(commande.sousZoneDepart) ?? '';
        final arrivee = _normalizeZone(commande.sousZoneArrivee) ?? '';
        if (!depart.contains(zone) && !arrivee.contains(zone)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String? _normalizeZone(String? value) {
    if (value == null) return null;
    final upper = value.toUpperCase();
    return upper
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ë', 'E')
        .replaceAll('Á', 'A')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ä', 'A')
        .replaceAll('Í', 'I')
        .replaceAll('Ì', 'I')
        .replaceAll('Î', 'I')
        .replaceAll('Ï', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ò', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Ö', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ù', 'U')
        .replaceAll('Û', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ç', 'C');
  }

  String _normalizeModePaiement(String? value) {
    if (value == null) return '';
    return value.toUpperCase().replaceAll(' ', '_');
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null) return null;
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    final match = RegExp(
      r'^(\\d{1,2})[/-](\\d{1,2})[/-](\\d{2,4})',
    ).firstMatch(raw);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    var year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    return DateTime(year, month, day);
  }

  String _formatDateTime(String? value) {
    final date = _parseDateTime(value);
    if (date == null) {
      return (value == null || value.trim().isEmpty) ? '-' : value;
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _dateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 7),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
    );
    if (picked == null) return;
    setState(() {
      _dateRange = picked;
    });
  }

  Future<void> _pickFactureDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _factureDateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 7),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
    );
    if (picked == null) return;
    setState(() {
      _factureDateRange = picked;
    });
  }

  Future<void> _openPayByFactureDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _PayByFactureDialog(
          parentContext: context,
          onSuccess: _fetchGains,
        );
      },
    );
  }
}

class _PayByFactureDialog extends StatefulWidget {
  final BuildContext parentContext;
  final VoidCallback onSuccess;

  const _PayByFactureDialog({
    required this.parentContext,
    required this.onSuccess,
  });

  @override
  State<_PayByFactureDialog> createState() => _PayByFactureDialogState();
}

class _PayByFactureDialogState extends State<_PayByFactureDialog> {
  bool _isSaving = false;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.9),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Paiement par facture',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isSaving
                                  ? null
                                  : () async {
                                    final image = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85,
                                    );
                                    if (image == null) return;
                                    final bytes = await image.readAsBytes();
                                    if (!mounted) return;
                                    setState(() {
                                      _pickedImage = image;
                                      _pickedImageBytes = bytes;
                                    });
                                  },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galerie'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isSaving
                                  ? null
                                  : () async {
                                    final image = await ImagePicker().pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 85,
                                    );
                                    if (image == null) return;
                                    final bytes = await image.readAsBytes();
                                    if (!mounted) return;
                                    setState(() {
                                      _pickedImage = image;
                                      _pickedImageBytes = bytes;
                                    });
                                  },
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                  if (_pickedImage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _pickedImage!.name,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _pickedImageBytes ?? Uint8List(0),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const SizedBox(
                              height: 160,
                              child: Center(child: Text('Apercu indisponible')),
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : () async {
                                if (_pickedImage == null) {
                                  ScaffoldMessenger.of(
                                    widget.parentContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Image requise.'),
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _isSaving = true;
                                });
                                try {
                                  final auth = context.read<AuthController>();
                                  final livreurId =
                                      auth.currentUser.value?.id ?? '';
                                  await FactureService().createWithImage(
                                    image: _pickedImage!,
                                    montant: 0.0,
                                    dateTimle: DateTime.now().toIso8601String(),
                                    idLivreur: livreurId,
                                    type: FactureType.livreurVerseEntreprise,
                                    confirmer: FactureConfirmation.nonTraiter,
                                  );
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  widget.onSuccess();
                                  ScaffoldMessenger.of(
                                    widget.parentContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Facture envoyee.'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(
                                    widget.parentContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: ${e.toString()}'),
                                    ),
                                  );
                                } finally {
                                  if (!mounted) return;
                                  setState(() {
                                    _isSaving = false;
                                  });
                                }
                              },
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CommandesLivreesSection extends StatefulWidget {
  final List<Commande> commandes;
  final List<String> modes;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  final DateTimeRange? dateRange;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDateRange;
  final int pageSize;

  const _CommandesLivreesSection({
    required this.commandes,
    required this.modes,
    required this.selectedMode,
    required this.onModeChanged,
    required this.dateRange,
    required this.onPickDateRange,
    required this.onClearDateRange,
    this.pageSize = 10,
  });

  @override
  State<_CommandesLivreesSection> createState() =>
      _CommandesLivreesSectionState();
}

class _CommandesLivreesSectionState extends State<_CommandesLivreesSection> {
  int _page = 1;

  @override
  void didUpdateWidget(covariant _CommandesLivreesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commandes != widget.commandes ||
        oldWidget.pageSize != widget.pageSize) {
      _page = 1;
    }
  }

  void _goPrev() {
    if (_page <= 1) return;
    setState(() {
      _page -= 1;
    });
  }

  void _goNext(int totalPages) {
    if (_page >= totalPages) return;
    setState(() {
      _page += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.commandes.length;
    final totalPages =
        total == 0 ? 1 : ((total + widget.pageSize - 1) ~/ widget.pageSize);
    final start =
        (total == 0)
            ? 0
            : (widget.pageSize * (_page - 1)).clamp(0, total).toInt();
    final end =
        (total == 0) ? 0 : (start + widget.pageSize).clamp(0, total).toInt();
    final pageItems = widget.commandes.sublist(start, end);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique des commandes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterChip(
                label: _formatRangeLabel(widget.dateRange),
                icon: Icons.date_range,
                onTap: widget.onPickDateRange,
              ),
              if (widget.dateRange != null)
                _FilterChip(
                  label: 'Effacer',
                  icon: Icons.close,
                  onTap: widget.onClearDateRange,
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EFE6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.selectedMode,
                    isDense: true,
                    onChanged: (value) {
                      if (value == null) return;
                      widget.onModeChanged(value);
                    },
                    items:
                        widget.modes
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(
                                  _labelForMode(mode),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4E5A52),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          widget.commandes.isEmpty
              ? Text(
                'Aucune commande disponible.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B776E),
                ),
              )
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 48,
                  columnSpacing: 18,
                  headingTextStyle: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4E5A52),
                  ),
                  columns: const [
                    DataColumn(label: Text('Zone depart')),
                    DataColumn(label: Text('Zone arrivee')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Prix')),
                    DataColumn(label: Text('')),
                  ],
                  rows:
                      pageItems.map((commande) {
                        final zoneDepart = _formatZone(
                          commande.zonePrincipaleDepart,
                          commande.sousZoneDepart,
                        );
                        final zoneArrivee = _formatZone(
                          commande.zonePrincipaleArrivee,
                          commande.sousZoneArrivee,
                        );
                        final dateCommande = _formatDate(commande.dateDemande);
                        final prix = _formatMoney(commande.prix ?? 0);
                        return DataRow(
                          cells: [
                            DataCell(Text(zoneDepart)),
                            DataCell(Text(zoneArrivee)),
                            DataCell(Text(dateCommande)),
                            DataCell(Text(prix)),
                            DataCell(
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder:
                                          (_) => CommandeDetailsPage(
                                            commande: commande,
                                          ),
                                    ),
                                  );
                                },
                                child: const Text('Detail'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
          if (widget.commandes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page $_page / $totalPages',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B776E),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _page > 1 ? _goPrev : null,
                      child: const Text('Precedent'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed:
                          _page < totalPages ? () => _goNext(totalPages) : null,
                      child: const Text('Suivant'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatZone(String? zone, String? sousZone) {
    final zoneLabel = (zone == null || zone.trim().isEmpty) ? '-' : zone;
    final sousZoneLabel =
        (sousZone == null || sousZone.trim().isEmpty) ? '-' : sousZone;
    return '$zoneLabel / $sousZoneLabel';
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  static String _formatRangeLabel(DateTimeRange? range) {
    if (range == null) return 'Toutes dates';
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  static String _formatMoney(double value) => '${value.toStringAsFixed(2)} DT';

  static String _labelForMode(String mode) {
    switch (mode) {
      case 'EN_LIGNE':
        return 'En ligne';
      case 'HORS_LIGNE':
        return 'Hors ligne';
      default:
        return mode;
    }
  }
}

class _FacturesSection extends StatelessWidget {
  final List<Facture> factures;
  final FactureType? selectedType;
  final ValueChanged<FactureType?> onTypeChanged;
  final DateTimeRange? dateRange;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDateRange;

  const _FacturesSection({
    required this.factures,
    required this.selectedType,
    required this.onTypeChanged,
    required this.dateRange,
    required this.onPickDateRange,
    required this.onClearDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facturesAcceptees =
        factures
            .where(
              (facture) => facture.confirmer == FactureConfirmation.acceter,
            )
            .toList();
    final facturesEnAttente =
        factures
            .where(
              (facture) => facture.confirmer == FactureConfirmation.nonTraiter,
            )
            .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique des factures',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterChip(
                label: _formatRangeLabel(dateRange),
                icon: Icons.date_range,
                onTap: onPickDateRange,
              ),
              if (dateRange != null)
                _FilterChip(
                  label: 'Effacer',
                  icon: Icons.close,
                  onTap: onClearDateRange,
                ),
              FilterChip(
                label: const Text('Tous'),
                selected: selectedType == null,
                onSelected: (_) => onTypeChanged(null),
                selectedColor: const Color(0xFFE9EFE6),
                showCheckmark: false,
              ),
              FilterChip(
                label: const Text('Vert livreur'),
                selected: selectedType == FactureType.entrepriseVerseLivreur,
                onSelected:
                    (_) => onTypeChanged(FactureType.entrepriseVerseLivreur),
                selectedColor: const Color(0xFFE9EFE6),
                showCheckmark: false,
              ),
              FilterChip(
                label: const Text('Vert entreprise'),
                selected: selectedType == FactureType.livreurVerseEntreprise,
                onSelected:
                    (_) => onTypeChanged(FactureType.livreurVerseEntreprise),
                selectedColor: const Color(0xFFE9EFE6),
                showCheckmark: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFactureTable(
            context,
            title: 'Factures acceptees',
            factures: facturesAcceptees,
          ),
          const SizedBox(height: 16),
          _buildFactureTable(
            context,
            title: 'Factures en attente',
            factures: facturesEnAttente,
            showType: false,
            showMontant: false,
          ),
        ],
      ),
    );
  }

  Widget _buildFactureTable(
    BuildContext context, {
    required String title,
    required List<Facture> factures,
    bool showType = true,
    bool showMontant = true,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 8),
        factures.isEmpty
            ? Text(
              'Aucune facture disponible.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B776E),
              ),
            )
            : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 48,
                columnSpacing: 18,
                headingTextStyle: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4E5A52),
                ),
                columns: [
                  if (showType) const DataColumn(label: Text('Type')),
                  const DataColumn(label: Text('Date')),
                  if (showMontant) const DataColumn(label: Text('Montant')),
                  const DataColumn(label: Text('')),
                ],
                rows:
                    factures.map((facture) {
                      return DataRow(
                        cells: [
                          if (showType)
                            DataCell(Text(_labelForType(facture.type))),
                          DataCell(Text(_formatDate(facture.dateTimle))),
                          if (showMontant)
                            DataCell(Text(_formatMoney(facture.montant))),
                          DataCell(
                            TextButton(
                              onPressed:
                                  facture.image == null ||
                                          facture.image!.trim().isEmpty
                                      ? null
                                      : () =>
                                          _showFactureImage(context, facture),
                              child: const Text('Detail'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
      ],
    );
  }

  static String _labelForType(FactureType type) {
    switch (type) {
      case FactureType.entrepriseVerseLivreur:
        return 'Vert livreur';
      case FactureType.livreurVerseEntreprise:
        return 'Vert entreprise';
    }
  }

  static String _formatDate(String? value) {
    if (value == null) return '-';
    final raw = value.trim();
    if (raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return value;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }

  static String _formatRangeLabel(DateTimeRange? range) {
    if (range == null) return 'Toutes dates';
    return '${_formatDate(range.start.toIso8601String())} - '
        '${_formatDate(range.end.toIso8601String())}';
  }

  static String _formatMoney(double value) => '${value.toStringAsFixed(2)} DT';
}

void _showFactureImage(BuildContext context, Facture facture) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final url = facture.image?.trim() ?? '';
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Facture',
                      style: Theme.of(dialogContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (url.isEmpty)
                const Text('Aucune image disponible.')
              else
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, _, __) {
                        return const Center(
                          child: Text('Impossible de charger l\'image.'),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EFE6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF4E5A52)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4E5A52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemiCircularGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final Color color;
  final Color backgroundColor;

  const _SemiCircularGauge({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    final percent = max <= min ? 0.0 : (clamped - min) / (max - min);
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 120),
            painter: _SemiCircularGaugePainter(
              percent: percent,
              color: color,
              backgroundColor: backgroundColor,
            ),
          ),
          Positioned(
            bottom: 8,
            child: Column(
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SemiCircularGaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color backgroundColor;

  _SemiCircularGaugePainter({
    required this.percent,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width / 2) - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final valuePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    const startAngle = 3.141592653589793;
    const sweepAngle = 3.141592653589793;
    canvas.drawArc(rect, startAngle, sweepAngle, false, basePaint);
    canvas.drawArc(rect, startAngle, sweepAngle * percent, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant _SemiCircularGaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SousZoneRingWithMetrics extends StatelessWidget {
  final List<_ZoneBreakdown> segments;
  final int? activeIndex;
  final double progress;
  final ValueChanged<int> onSegmentTap;
  final ValueChanged<int>? onSegmentHover;
  final VoidCallback? onHoverExit;

  const _SousZoneRingWithMetrics({
    required this.segments,
    required this.activeIndex,
    required this.progress,
    required this.onSegmentTap,
    this.onSegmentHover,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    final safeSegments = segments.take(2).toList();
    final resolvedActiveIndex =
        safeSegments.isNotEmpty &&
                activeIndex != null &&
                activeIndex! >= 0 &&
                activeIndex! < safeSegments.length
            ? activeIndex!
            : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final maxSide = math.min(constraints.maxWidth, 320).toDouble();
        final ringSize = isCompact ? maxSide : math.min(maxSide, 280.0);

        final ring = _RingSegmented(
          size: ringSize,
          segments: safeSegments,
          activeIndex: resolvedActiveIndex,
          progress: progress,
          onSegmentTap: onSegmentTap,
          onSegmentHover: onSegmentHover,
          onHoverExit: onHoverExit,
        );

        final metrics = _MetricsPanel(
          segments: safeSegments,
          activeIndex: resolvedActiveIndex,
          currencyFormatter: (value) => '${value.toStringAsFixed(2)} DT',
          onTap: onSegmentTap,
          onHover: onSegmentHover,
          onHoverExit: onHoverExit,
        );

        if (isCompact) {
          return Column(
            children: [
              Center(child: ring),
              const SizedBox(height: 14),
              metrics,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: ringSize, height: ringSize, child: ring),
            const SizedBox(width: 16),
            Expanded(flex: 9, child: metrics),
          ],
        );
      },
    );
  }
}

class _RingSegmented extends StatelessWidget {
  final double size;
  final List<_ZoneBreakdown> segments;
  final int activeIndex;
  final double progress;
  final ValueChanged<int> onSegmentTap;
  final ValueChanged<int>? onSegmentHover;
  final VoidCallback? onHoverExit;

  const _RingSegmented({
    required this.size,
    required this.segments,
    required this.activeIndex,
    required this.progress,
    required this.onSegmentTap,
    this.onSegmentHover,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (segments.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text('Aucune donnee', style: theme.textTheme.bodySmall),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Builder(
          builder:
              (ringContext) => MouseRegion(
                onExit: (_) => onHoverExit?.call(),
                onHover: (event) {
                  if (onSegmentHover == null) return;
                  final box = ringContext.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final local = box.globalToLocal(event.position);
                  final index = _hitTestSegment(local, box.size, segments);
                  if (index != null) onSegmentHover!(index);
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final box = ringContext.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final local = details.localPosition;
                    final index = _hitTestSegment(local, box.size, segments);
                    if (index != null) onSegmentTap(index);
                  },
                  child: CustomPaint(
                    painter: _SegmentedRingPainter(
                      segments: segments,
                      activeIndex: activeIndex,
                      progress: progress,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${segments[activeIndex.clamp(0, segments.length - 1)].percent.toStringAsFixed(0)}%',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              segments[activeIndex.clamp(
                                    0,
                                    segments.length - 1,
                                  )]
                                  .name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Part du revenu total',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF6B776E),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }

  int? _hitTestSegment(Offset local, Size size, List<_ZoneBreakdown> segments) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final outerRadius =
        (size.width / 2) - (_SegmentedRingPainter.strokeWidth / 2);
    const strokeWidth = _SegmentedRingPainter.strokeWidth;
    final innerRadius = outerRadius - strokeWidth;
    if (distance < innerRadius || distance > outerRadius) return null;

    var angle = math.atan2(dy, dx);
    const startAngle = -math.pi / 2;
    final normalized = (angle - startAngle + math.pi * 2) % (math.pi * 2);
    var current = 0.0;

    for (var i = 0; i < segments.length; i++) {
      final sweep = (segments[i].percent / 100) * math.pi * 2;
      final end = current + sweep;
      if (normalized >= current && normalized <= end) {
        return i;
      }
      current = end;
    }
    return null;
  }
}

class _SegmentedRingPainter extends CustomPainter {
  static const double strokeWidth = 18.0;

  final List<_ZoneBreakdown> segments;
  final int activeIndex;
  final double progress;

  _SegmentedRingPainter({
    required this.segments,
    required this.activeIndex,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint =
        Paint()
          ..color = const Color(0xFFE2E8E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, basePaint);

    final total = segments.fold<double>(0, (sum, seg) => sum + seg.percent);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (var i = 0; i < segments.length; i++) {
      final rawSweep = (segments[i].percent / 100) * math.pi * 2;
      final sweep = rawSweep * progress;
      if (rawSweep <= 0) {
        startAngle += rawSweep;
        continue;
      }

      final isActive = i == activeIndex;

      final segmentPaint =
          Paint()
            ..color =
                isActive
                    ? segments[i].color.withOpacity(0.98)
                    : segments[i].color.withOpacity(0.92)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isActive ? strokeWidth + 2 : strokeWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweep, false, segmentPaint);

      startAngle += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.progress != progress;
  }
}

class _MetricsPanel extends StatelessWidget {
  final List<_ZoneBreakdown> segments;
  final int activeIndex;
  final String Function(double) currencyFormatter;
  final ValueChanged<int> onTap;
  final ValueChanged<int>? onHover;
  final VoidCallback? onHoverExit;

  const _MetricsPanel({
    required this.segments,
    required this.activeIndex,
    required this.currencyFormatter,
    required this.onTap,
    this.onHover,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MetricRow(
            data: segments[0],
            isActive: activeIndex == 0,
            formattedValue: currencyFormatter(segments[0].value),
            onTap: () => onTap(0),
            onHoverEnter: onHover == null ? null : () => onHover!(0),
            onHoverExit: onHoverExit,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.dividerColor.withOpacity(0.4),
            ),
          ),
          if (segments.length > 1)
            _MetricRow(
              data: segments[1],
              isActive: activeIndex == 1,
              formattedValue: currencyFormatter(segments[1].value),
              onTap: () => onTap(1),
              onHoverEnter: onHover == null ? null : () => onHover!(1),
              onHoverExit: onHoverExit,
            ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final _ZoneBreakdown data;
  final bool isActive;
  final String formattedValue;
  final VoidCallback onTap;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;

  const _MetricRow({
    required this.data,
    required this.isActive,
    required this.formattedValue,
    required this.onTap,
    this.onHoverEnter,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => onHoverEnter?.call(),
      onExit: (_) => onHoverExit?.call(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? data.color.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedValue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B776E),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${data.percent.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F1F1F),
                    ),
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

class _ZoneBreakdown {
  final String name;
  final double percent;
  final double value;
  final Color color;

  const _ZoneBreakdown({
    required this.name,
    required this.percent,
    required this.value,
    required this.color,
  });
}

class _GainsError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _GainsError({required this.error, required this.onRetry});

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
            'Impossible de charger les gains.',
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
