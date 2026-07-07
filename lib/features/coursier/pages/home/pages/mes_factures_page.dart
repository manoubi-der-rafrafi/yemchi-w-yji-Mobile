import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/facture.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/services/transporteur_factures_cache_service.dart';
import 'package:yemchi_wyji/features/coursier/pages/home/services/transporteur_stats_cache_service.dart';
import 'package:yemchi_wyji/features/facture/data/facture_service.dart';

class MesFacturesPage extends StatefulWidget {
  const MesFacturesPage({super.key});

  @override
  State<MesFacturesPage> createState() => _MesFacturesPageState();
}

class _MesFacturesPageState extends State<MesFacturesPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoadedData = false;
  String? _error;
  List<Facture> _factures = [];
  FactureType? _typeFilter;
  DateTimeRange? _dateRange;
  final FactureService _factureService = FactureService();
  final TransporteurFacturesCacheService _cacheService =
      TransporteurFacturesCacheService();
  final TransporteurStatsCacheService _statsCacheService =
      TransporteurStatsCacheService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  String? get _livreurId =>
      context.read<AuthController>().currentUser.value?.id;

  Future<void> _loadInitialData() async {
    final livreurId = _livreurId;
    if (livreurId == null || livreurId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'Utilisateur non connecte';
        _isLoading = false;
      });
      return;
    }

    final cachedFactures = await _cacheService.read(livreurId);
    if (!mounted) return;
    if (cachedFactures != null) {
      setState(() {
        _applyFactures(cachedFactures.factures);
        _isLoading = false;
        _error = null;
      });
      unawaited(_fetchFactures(silent: true));
      return;
    }

    final cachedStats = await _statsCacheService.read(livreurId);
    if (!mounted) return;
    if (cachedStats != null) {
      setState(() {
        _applyFactures(cachedStats.factures);
        _isLoading = false;
        _error = null;
      });
      unawaited(_fetchFactures(silent: true));
      return;
    }

    await _fetchFactures();
  }

  void _sortFactures(List<Facture> factures) {
    factures.sort((a, b) {
      final da = _parseDate(a.dateTimle);
      final db = _parseDate(b.dateTimle);
      if (da == null && db == null) {
        return b.dateTimle.compareTo(a.dateTimle);
      }
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
  }

  void _applyFactures(List<Facture> factures) {
    _factures = List<Facture>.from(factures);
    _sortFactures(_factures);
    _hasLoadedData = true;
  }

  Future<void> _fetchFactures({bool silent = false}) async {
    final livreurId = _livreurId;
    if (livreurId == null || livreurId.isEmpty) {
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
      final factures = await _factureService.listByLivreurId(livreurId);
      _sortFactures(factures);
      await _cacheService.write(
        TransporteurFacturesCacheEntry(
          transporteurId: livreurId,
          cachedAt: DateTime.now(),
          factures: factures,
        ),
      );
      if (!mounted) return;
      setState(() {
        _applyFactures(factures);
        _isLoading = false;
        _isRefreshing = false;
      });
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

  List<Facture> _filteredFactures() {
    return _factures.where((facture) {
      if (_typeFilter != null && facture.type != _typeFilter) {
        return false;
      }
      if (_dateRange != null) {
        final date = _parseDate(facture.dateTimle);
        if (date == null) return false;
        final dateOnly = DateTime(date.year, date.month, date.day);
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
        );
        if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  DateTime? _parseDate(String? value) {
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

  String _formatDate(String? value) {
    final date = _parseDate(value);
    if (date == null) {
      return (value == null || value.trim().isEmpty) ? '-' : value;
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatRangeLabel(DateTimeRange? range) {
    if (range == null) return 'Toutes dates';
    return '${_formatDate(range.start.toIso8601String())} - '
        '${_formatDate(range.end.toIso8601String())}';
  }

  String _formatMoney(double value) => '${value.toStringAsFixed(2)} DT';

  String _labelForType(FactureType type) {
    switch (type) {
      case FactureType.entrepriseVerseLivreur:
        return 'Vert livreur';
      case FactureType.livreurVerseEntreprise:
        return 'Vert entreprise';
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredFactures();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes factures'),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _fetchFactures,
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
                ? _FacturesError(error: _error!, onRetry: _fetchFactures)
                : Stack(
                  children: [
                    ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8F2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.04),
                            ),
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
                                    label: _formatRangeLabel(_dateRange),
                                    icon: Icons.date_range,
                                    onTap: _pickDateRange,
                                  ),
                                  if (_dateRange != null)
                                    _FilterChip(
                                      label: 'Effacer',
                                      icon: Icons.close,
                                      onTap: () {
                                        setState(() {
                                          _dateRange = null;
                                        });
                                      },
                                    ),
                                  FilterChip(
                                    label: const Text('Tous'),
                                    selected: _typeFilter == null,
                                    onSelected: (_) {
                                      setState(() {
                                        _typeFilter = null;
                                      });
                                    },
                                    selectedColor: const Color(0xFFE9EFE6),
                                    showCheckmark: false,
                                  ),
                                  FilterChip(
                                    label: const Text('Vert livreur'),
                                    selected:
                                        _typeFilter ==
                                        FactureType.entrepriseVerseLivreur,
                                    onSelected: (_) {
                                      setState(() {
                                        _typeFilter =
                                            FactureType.entrepriseVerseLivreur;
                                      });
                                    },
                                    selectedColor: const Color(0xFFE9EFE6),
                                    showCheckmark: false,
                                  ),
                                  FilterChip(
                                    label: const Text('Vert entreprise'),
                                    selected:
                                        _typeFilter ==
                                        FactureType.livreurVerseEntreprise,
                                    onSelected: (_) {
                                      setState(() {
                                        _typeFilter =
                                            FactureType.livreurVerseEntreprise;
                                      });
                                    },
                                    selectedColor: const Color(0xFFE9EFE6),
                                    showCheckmark: false,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              filtered.isEmpty
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
                                      headingTextStyle: theme
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF4E5A52),
                                          ),
                                      columns: const [
                                        DataColumn(label: Text('Type')),
                                        DataColumn(label: Text('Date')),
                                        DataColumn(label: Text('Montant')),
                                      ],
                                      rows:
                                          filtered.map((facture) {
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    _labelForType(facture.type),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    _formatDate(
                                                      facture.dateTimle,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    _formatMoney(
                                                      facture.montant,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                    ),
                                  ),
                            ],
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

class _FacturesError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _FacturesError({required this.error, required this.onRetry});

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
            'Impossible de charger les factures.',
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
