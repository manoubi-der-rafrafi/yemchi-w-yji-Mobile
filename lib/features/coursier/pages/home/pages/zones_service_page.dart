import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';

class ZonesServicePage extends StatefulWidget {
  const ZonesServicePage({super.key});

  @override
  State<ZonesServicePage> createState() => _ZonesServicePageState();
}

class _ZonesServicePageState extends State<ZonesServicePage> {
  static const _modeSame = 0;
  static const _modeSeparate = 1;
  int _selectionMode = _modeSame;
  int _separateTarget = 0;
  bool _saving = false;

  static const Map<Zone, List<SousZone>> _zonesToSousZones = {
    Zone.GRAND_TUNIS: [
      SousZone.TUNIS,
      SousZone.ARIANA,
      SousZone.BEN_AROUS,
      SousZone.MANOUBA,
    ],
    Zone.NORD_EST: [
      SousZone.BIZERTE,
      SousZone.NABEUL,
    ],
    Zone.NORD_OUEST: [
      SousZone.BEJA,
      SousZone.JENDOUBA,
      SousZone.KEF,
      SousZone.SILIANA,
    ],
    Zone.CENTRE: [
      SousZone.ZAGHOUAN,
      SousZone.KAIROUAN,
    ],
    Zone.CENTRE_OUEST: [
      SousZone.KASSERINE,
      SousZone.SIDI_BOUZID,
    ],
    Zone.SAHEL: [
      SousZone.SOUSSE,
      SousZone.MONASTIR,
      SousZone.MAHDIA,
    ],
    Zone.SFAX: [
      SousZone.SFAX,
    ],
    Zone.SUD_EST: [
      SousZone.GABES,
      SousZone.MEDENINE,
      SousZone.TATAOUINE,
    ],
    Zone.SUD_OUEST: [
      SousZone.GAFSA,
      SousZone.TOZEUR,
      SousZone.KEBILI,
    ],
  };

  final Set<Zone> _selectedZonesShared = <Zone>{};
  final Set<SousZone> _selectedSousZonesShared = <SousZone>{};
  final Set<Zone> _selectedZonesDepart = <Zone>{};
  final Set<SousZone> _selectedSousZonesDepart = <SousZone>{};
  final Set<Zone> _selectedZonesArrivee = <Zone>{};
  final Set<SousZone> _selectedSousZonesArrivee = <SousZone>{};

  @override
  void initState() {
    super.initState();
    _applyInitialSelections();
  }

  void _applyInitialSelections() {
    final auth = context.read<AuthController>();
    final user = auth.currentUser.value;
    final departRaw = user?.zoneDepart ?? const <String, List<String>>{};
    final arriveeRaw = user?.zoneArriver ?? const <String, List<String>>{};

    final departZones = _extractZones(departRaw);
    final arriveeZones = _extractZones(arriveeRaw);
    final departSousZones = _extractSousZones(departRaw);
    final arriveeSousZones = _extractSousZones(arriveeRaw);

    final bool hasDepart = departZones.isNotEmpty || departSousZones.isNotEmpty;
    final bool hasArrivee =
        arriveeZones.isNotEmpty || arriveeSousZones.isNotEmpty;
    final bool sameSelection = _sameZoneSelection(departRaw, arriveeRaw);

    if (hasDepart && hasArrivee && sameSelection) {
      _selectionMode = _modeSame;
      _selectedZonesShared
        ..clear()
        ..addAll(departZones);
      _selectedSousZonesShared
        ..clear()
        ..addAll(departSousZones);
    } else if (hasDepart || hasArrivee) {
      _selectionMode = _modeSeparate;
      _selectedZonesDepart
        ..clear()
        ..addAll(departZones);
      _selectedSousZonesDepart
        ..clear()
        ..addAll(departSousZones);
      _selectedZonesArrivee
        ..clear()
        ..addAll(arriveeZones);
      _selectedSousZonesArrivee
        ..clear()
        ..addAll(arriveeSousZones);
    }
  }

  String _prettyLabel(String raw) {
    return raw
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Set<Zone> _extractZones(Map<String, List<String>> raw) {
    final result = <Zone>{};
    for (final key in raw.keys) {
      final zone = _zoneFromName(key);
      if (zone != null) {
        result.add(zone);
      }
    }
    return result;
  }

  Set<SousZone> _extractSousZones(Map<String, List<String>> raw) {
    final result = <SousZone>{};
    for (final entry in raw.entries) {
      for (final value in entry.value) {
        final zone = _sousZoneFromName(value);
        if (zone != null) {
          result.add(zone);
        }
      }
    }
    return result;
  }

  Zone? _zoneFromName(String raw) {
    final normalized = raw.trim().toUpperCase();
    for (final z in Zone.values) {
      if (z.name.toUpperCase() == normalized) {
        return z;
      }
    }
    return null;
  }

  SousZone? _sousZoneFromName(String raw) {
    final normalized = raw.trim().toUpperCase();
    for (final sz in SousZone.values) {
      if (sz.name.toUpperCase() == normalized) {
        return sz;
      }
    }
    return null;
  }

  bool _sameZoneSelection(
    Map<String, List<String>> left,
    Map<String, List<String>> right,
  ) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      final key = entry.key;
      if (!right.containsKey(key)) return false;
      final leftSet = entry.value.toSet();
      final rightSet = right[key]!.toSet();
      if (leftSet.length != rightSet.length) return false;
      if (!leftSet.containsAll(rightSet)) return false;
    }
    return true;
  }

  void _toggleZone(
    Zone zone,
    bool? checked,
    Set<Zone> selectedZones,
    Set<SousZone> selectedSousZones,
  ) {
    final relatedSousZones = _zonesToSousZones[zone] ?? const <SousZone>[];
    setState(() {
      if (checked == true) {
        selectedZones.add(zone);
        selectedSousZones.addAll(relatedSousZones);
      } else {
        selectedZones.remove(zone);
        selectedSousZones.removeAll(relatedSousZones);
      }
    });
  }

  void _toggleSousZone(
    Zone zone,
    SousZone sousZone,
    bool? checked,
    Set<Zone> selectedZones,
    Set<SousZone> selectedSousZones,
  ) {
    final relatedSousZones = _zonesToSousZones[zone] ?? const <SousZone>[];
    setState(() {
      if (checked == true) {
        selectedSousZones.add(sousZone);
      } else {
        selectedSousZones.remove(sousZone);
      }
      final allSelected =
          relatedSousZones.every((sz) => selectedSousZones.contains(sz));
      if (allSelected) {
        selectedZones.add(zone);
      } else {
        selectedZones.remove(zone);
      }
    });
  }

  void _schedulePruneSousZones(
    Set<SousZone> selectedSousZones,
    List<SousZone> allowed,
  ) {
    final hasDisallowed =
        selectedSousZones.any((zone) => !allowed.contains(zone));
    if (!hasDisallowed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        selectedSousZones.removeWhere((zone) => !allowed.contains(zone));
      });
    });
  }

  Map<String, List<String>> _buildZoneMap({
    required Set<Zone> selectedZones,
    required Set<SousZone> selectedSousZones,
    required Zone? forcedZone,
  }) {
    final map = <String, List<String>>{};
    if (forcedZone != null) {
      final allowed = _zonesToSousZones[forcedZone] ?? const <SousZone>[];
      final items = allowed
          .where((sz) => selectedSousZones.contains(sz))
          .map((sz) => sz.name)
          .toList();
      map[forcedZone.name] = items;
      return map;
    }
    for (final zone in selectedZones) {
      final allowed = _zonesToSousZones[zone] ?? const <SousZone>[];
      final items = allowed
          .where((sz) => selectedSousZones.contains(sz))
          .map((sz) => sz.name)
          .toList();
      map[zone.name] = items;
    }
    return map;
  }

  Future<void> _applySelection({
    required Zone? forcedZone,
  }) async {
    final auth = context.read<AuthController>();
    final bool hasSharedSelection = _selectedSousZonesShared.isNotEmpty;
    final bool hasDepartSelection = _selectedSousZonesDepart.isNotEmpty;
    final bool hasArriveeSelection = _selectedSousZonesArrivee.isNotEmpty;
    final bool canApply = _selectionMode == _modeSame
        ? hasSharedSelection
        : (hasDepartSelection && hasArriveeSelection);
    if (!canApply) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectionMode == _modeSame
                ? 'Veuillez choisir au moins une sous-zone.'
                : 'Veuillez choisir au moins une sous-zone de depart et une d\'arrivee.',
          ),
        ),
      );
      return;
    }
    final zoneDepart = _selectionMode == _modeSame
        ? _buildZoneMap(
            selectedZones: _selectedZonesShared,
            selectedSousZones: _selectedSousZonesShared,
            forcedZone: forcedZone,
          )
        : _buildZoneMap(
            selectedZones: _selectedZonesDepart,
            selectedSousZones: _selectedSousZonesDepart,
            forcedZone: forcedZone,
          );
    final zoneArriver = _selectionMode == _modeSame
        ? _buildZoneMap(
            selectedZones: _selectedZonesShared,
            selectedSousZones: _selectedSousZonesShared,
            forcedZone: forcedZone,
          )
        : _buildZoneMap(
            selectedZones: _selectedZonesArrivee,
            selectedSousZones: _selectedSousZonesArrivee,
            forcedZone: forcedZone,
          );

    setState(() => _saving = true);
    try {
      final ok = await auth.updateZonesDepartArriver(
        zoneDepart: zoneDepart,
        zoneArriver: zoneArriver,
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zones mises a jour.')),
        );
        Navigator.of(context).pop();
      } else {
        final message = auth.error.value ?? 'Impossible de mettre a jour.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildSelectionBlock({
    required String title,
    required Set<Zone> selectedZones,
    required Set<SousZone> selectedSousZones,
    Zone? forcedZone,
    bool disableAll = false,
  }) {
    if (forcedZone != null) {
      final allowedSousZones =
          _zonesToSousZones[forcedZone] ?? const <SousZone>[];
      _schedulePruneSousZones(selectedSousZones, allowedSousZones);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_outlined),
                const SizedBox(width: 8),
                Text(_prettyLabel(forcedZone.name)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (allowedSousZones.isEmpty)
            const Text('Aucune sous-zone disponible pour cette zone.')
          else
            ...allowedSousZones.map(
              (sousZone) => CheckboxListTile(
                value: selectedSousZones.contains(sousZone),
                onChanged: disableAll
                    ? null
                    : (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedSousZones.add(sousZone);
                          } else {
                            selectedSousZones.remove(sousZone);
                          }
                        });
                      },
                title: Text(_prettyLabel(sousZone.name)),
                dense: true,
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ..._zonesToSousZones.entries.map(
          (entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: selectedZones.contains(entry.key),
                onChanged: disableAll
                    ? null
                    : (checked) => _toggleZone(
                          entry.key,
                          checked,
                          selectedZones,
                          selectedSousZones,
                        ),
                title: Text(_prettyLabel(entry.key.name)),
                dense: true,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: entry.value
                      .map(
                        (sousZone) => CheckboxListTile(
                          value: selectedSousZones.contains(sousZone),
                          onChanged: disableAll
                              ? null
                              : (checked) => _toggleSousZone(
                                    entry.key,
                                    sousZone,
                                    checked,
                                    selectedZones,
                                    selectedSousZones,
                                  ),
                          title: Text(_prettyLabel(sousZone.name)),
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser.value;
    final isDeuxRoues =
        user?.typeVehicule == TypeVehicule.DEUX_ROUES_MOTORISES;
    final Zone? forcedZone = isDeuxRoues ? user?.zone : null;
    final bool disableSelection = isDeuxRoues && forcedZone == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zones de service'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (isDeuxRoues)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                forcedZone == null
                    ? 'Zone actuelle introuvable. Selection des sous-zones indisponible.'
                    : 'Deux roues: selection limitee aux sous-zones de votre zone actuelle.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Text(
            'Mode de selection',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          RadioListTile<int>(
            value: _modeSame,
            groupValue: _selectionMode,
            onChanged: (value) => setState(() {
              _selectionMode = value ?? _modeSame;
            }),
            title: const Text('Meme zones pour depart et arrivee'),
          ),
          RadioListTile<int>(
            value: _modeSeparate,
            groupValue: _selectionMode,
            onChanged: (value) => setState(() {
              _selectionMode = value ?? _modeSame;
            }),
            title: const Text('Zones separees (depart / arrivee)'),
          ),
          const SizedBox(height: 16),
          if (disableSelection)
            const SizedBox.shrink()
          else if (_selectionMode == _modeSame)
            _buildSelectionBlock(
              title: 'Zones de depart et arrivee',
              selectedZones: _selectedZonesShared,
              selectedSousZones: _selectedSousZonesShared,
              forcedZone: forcedZone,
            )
          else ...[
            Center(
              child: ToggleButtons(
                isSelected: [
                  _separateTarget == 0,
                  _separateTarget == 1,
                ],
                onPressed: (index) {
                  setState(() => _separateTarget = index);
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Depart'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Arrivee'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_separateTarget == 0)
              _buildSelectionBlock(
                title: 'Zones de depart',
                selectedZones: _selectedZonesDepart,
                selectedSousZones: _selectedSousZonesDepart,
                forcedZone: forcedZone,
              )
            else
              _buildSelectionBlock(
                title: 'Zones d\'arrivee',
                selectedZones: _selectedZonesArrivee,
                selectedSousZones: _selectedSousZonesArrivee,
                forcedZone: forcedZone,
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            onPressed: disableSelection || _saving
                ? null
                : () => _applySelection(forcedZone: forcedZone),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Appliquer'),
          ),
        ),
      ),
    );
  }
}
