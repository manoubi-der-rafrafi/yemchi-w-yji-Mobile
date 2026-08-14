// home_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';
import 'package:yemchi_wyji/features/commande/dto/commande_transporteur_principal_response.dart';
import 'package:yemchi_wyji/features/commande/dto/transporteur_panne_commandes_response.dart';
import 'package:yemchi_wyji/features/commande/dto/transporteur_secours_commandes_response.dart';

enum AppLang { ar, en }

enum CommandTab { mes, envoyees }

enum RoutePointOrigin { depart, destination, courier, contact }

class SelectedContactInfo {
  const SelectedContactInfo({
    required this.displayName,
    this.imageUrl,
    this.phoneDepart,
    this.phoneArrivee,
    this.isActive = true,
    this.preferCurrentPositionToArrivalWhenDepartScanned = false,
    this.routeStartLatitude,
    this.routeStartLongitude,
    this.routeTargetLatitude,
    this.routeTargetLongitude,
  });

  final String displayName;
  final String? imageUrl;
  final String? phoneDepart;
  final String? phoneArrivee;
  final bool isActive;
  final bool preferCurrentPositionToArrivalWhenDepartScanned;
  final double? routeStartLatitude;
  final double? routeStartLongitude;
  final double? routeTargetLatitude;
  final double? routeTargetLongitude;
}

class HomeController extends ChangeNotifier {
  HomeController(this._authController);

  final AuthController _authController;
  static const double kAverageCourierSpeedKmh = 28;

  AppLang currentLang = AppLang.en;

  // --- ÉTAT COMMANDES & ZONE COURANTE ---
  final List<Commande> _commandes = [];
  final List<Commande> _mesCommandes = [];
  final List<CommandeTransporteurPrincipalResponse> _mesCommandesSecours = [];
  final List<TransporteurPanneCommandesResponse> _transporteursEnPanne = [];
  final List<TransporteurSecoursCommandesResponse> _transporteursSecours = [];
  Map<String, bool> _minTransporteursByCommandeId = {};

  List<Commande> get commandes => List.unmodifiable(_commandes);
  List<Commande> get mesCommandes => List.unmodifiable(_mesCommandes);
  List<CommandeTransporteurPrincipalResponse> get mesCommandesSecours =>
      List.unmodifiable(_mesCommandesSecours);
  List<TransporteurPanneCommandesResponse> get transporteursEnPanne =>
      List.unmodifiable(_transporteursEnPanne);
  List<TransporteurSecoursCommandesResponse> get transporteursSecours =>
      List.unmodifiable(_transporteursSecours);
  bool get isCurrentTransporteurEnPanne =>
      _authController.currentUser.value?.etatIncident == EtatIncident.PANNE;
  bool get isCurrentTransporteurEnAccident =>
      _authController.currentUser.value?.etatIncident == EtatIncident.ACCIDENT;
  bool get isCurrentTransporteurIndisponible =>
      isCurrentTransporteurEnPanne || isCurrentTransporteurEnAccident;
  String? get currentTransporteurId => _authController.currentUser.value?.id;
  List<Commande> get activeCommandes =>
      isCurrentTransporteurIndisponible
          ? _mesCommandes
              .where(
                (commande) =>
                    (commande.transporteurSecoursId ?? '').trim().isEmpty,
              )
              .toList(growable: false)
          : (_commandTab == CommandTab.mes
              ? <Commande>[
                ..._mesCommandes,
                ..._mesCommandesSecours.map((entry) => entry.commande),
              ]
              : commandes);
  Map<String, bool> get minTransporteursByCommandeId =>
      Map.unmodifiable(_minTransporteursByCommandeId);
  bool get canResetCurrentIncident {
    if (!isCurrentTransporteurIndisponible) return false;
    final allCommandes = _transporteursSecours
        .expand((entry) => entry.commandes)
        .map((entry) => entry.commande)
        .toList(growable: false);
    if (allCommandes.isEmpty) return false;
    return allCommandes.every(
      (commande) => commande.statut?.trim().toLowerCase() == 'livree',
    );
  }

  bool isMinTransporteurForCommande(String commandeId) =>
      _minTransporteursByCommandeId[commandeId] == true;

  String? getTransporteurPanneIdForCommande(String commandeId) {
    for (final entry in _transporteursEnPanne) {
      final hasCommande = entry.commandes.any(
        (commandeEntry) => commandeEntry.commande.id == commandeId,
      );
      if (hasCommande) {
        return entry.transporteur.id;
      }
    }
    return null;
  }

  int minTransporteursSignatureFor(List<Commande> commandes) {
    if (commandes.isEmpty) return 0;
    final mapped = commandes.map(
      (c) => Object.hash(c.id, _minTransporteursByCommandeId[c.id] == true),
    );
    return Object.hashAll(mapped);
  }

  int transporteursEnPanneSignature() {
    if (_transporteursEnPanne.isEmpty) return 0;
    final mapped = _transporteursEnPanne.map(
      (entry) => Object.hash(
        entry.transporteur.id,
        entry.transporteur.latitude,
        entry.transporteur.longitude,
        entry.commandes.length,
      ),
    );
    return Object.hashAll(mapped);
  }

  int transporteursSecoursSignature() {
    if (_transporteursSecours.isEmpty) return 0;
    final mapped = _transporteursSecours.map(
      (entry) => Object.hash(
        entry.transporteurSecours.id,
        entry.transporteurSecours.latitude,
        entry.transporteurSecours.longitude,
        entry.commandes.length,
      ),
    );
    return Object.hashAll(mapped);
  }

  String? _currentZone; // ex: "GRAND_TUNIS"
  String? get currentZone => _currentZone;

  String? selectedCommandeId;
  bool isPanelOpen = false;
  Commande? _selectedCommandeOverride;
  SelectedContactInfo? _selectedContactInfo;
  Commande? get selectedCommande =>
      _findCommandeById(selectedCommandeId) ?? _selectedCommandeOverride;
  SelectedContactInfo? get selectedContactInfo => _selectedContactInfo;
  bool get isSelectedCommandeMine {
    final id = selectedCommandeId;
    if (id == null) return false;
    return isCommandeMine(id);
  }

  bool isCommandeMine(String? commandeId) {
    if (commandeId == null) return false;
    return _mesCommandes.any((commande) => commande.id == commandeId) ||
        _mesCommandesSecours.any((entry) => entry.commande.id == commandeId);
  }

  bool isCommandeSecours(String? commandeId) {
    if (commandeId == null) return false;
    return _mesCommandesSecours.any((entry) => entry.commande.id == commandeId);
  }

  CommandeTransporteurPrincipalResponse? getCommandeSecoursDetails(
    String? commandeId,
  ) {
    if (commandeId == null) return null;
    for (final entry in _mesCommandesSecours) {
      if (entry.commande.id == commandeId) {
        return entry;
      }
    }
    return null;
  }

  SelectedContactInfo? buildSecoursContactInfoForCommande(String? commandeId) {
    final entry = getCommandeSecoursDetails(commandeId);
    if (entry == null) return null;
    final transporteur = entry.transporteur;
    final commande = entry.commande;
    final displayName =
        '${transporteur.prenom ?? ''} ${transporteur.nom ?? ''}'.trim();
    final bool departScanne = commande.qrCodeDepartScanne == true;
    final bool relaisEffectue = commande.relaisTransporteurEffectue == true;
    final bool shouldGoToTransporteur = departScanne && !relaisEffectue;
    return SelectedContactInfo(
      displayName: displayName.isEmpty ? 'Transporteur en panne' : displayName,
      imageUrl: transporteur.image,
      phoneDepart: commande.telDepart,
      phoneArrivee: commande.telArrivee,
      preferCurrentPositionToArrivalWhenDepartScanned:
          departScanne && relaisEffectue,
      routeTargetLatitude:
          shouldGoToTransporteur ? transporteur.latitude : null,
      routeTargetLongitude:
          shouldGoToTransporteur ? transporteur.longitude : null,
    );
  }

  CommandTab _commandTab = CommandTab.mes;
  CommandTab get commandTab => _commandTab;

  bool _isNavigationMode = false;
  bool get isNavigationMode => _isNavigationMode;

  void setNavigationMode(bool enabled) {
    if (_isNavigationMode == enabled) return;
    _isNavigationMode = enabled;
    notifyListeners();
  }

  void toggleNavigationMode() => setNavigationMode(!_isNavigationMode);

  LatLng? selectedStart;
  LatLng? selectedEnd;
  RoutePointOrigin? _selectedStartOrigin;
  RoutePointOrigin? _selectedEndOrigin;
  RoutePointOrigin? get selectedEndOrigin => _selectedEndOrigin;
  List<LatLng>? _currentPolyline;
  List<LatLng>? get currentPolyline =>
      _currentPolyline == null ? null : List.unmodifiable(_currentPolyline!);
  double? _currentRouteDistanceMeters;
  Duration? _currentRouteEta;
  double? get currentRouteDistanceMeters => _currentRouteDistanceMeters;
  Duration? get currentRouteEta => _currentRouteEta;
  final Distance _distanceCalculator = const Distance();

  // --- RAFRAÎCHISSEMENT AUTO ---
  Timer? _refreshTimer;
  Duration autoRefreshEvery = const Duration(seconds: 3);

  void setLang(AppLang lang) {
    currentLang = lang;
    notifyListeners();
  }

  void selectCommande(Commande? commande, {bool openPanel = true}) {
    if (commande == null) {
      clearSelection();
      return;
    }
    final idChanged = selectedCommandeId != commande.id;
    selectedCommandeId = commande.id;
    _selectedCommandeOverride =
        _findCommandeById(commande.id) == null ? commande : null;
    isPanelOpen = openPanel;
    if (idChanged) {
      resetRoute();
    }
    notifyListeners();
  }

  void setSelectedContactInfo(SelectedContactInfo? info, {bool notify = true}) {
    _selectedContactInfo = info;
    if (notify) {
      notifyListeners();
    }
  }

  void clearSelection({bool notify = true}) {
    selectedCommandeId = null;
    isPanelOpen = false;
    _selectedCommandeOverride = null;
    _selectedContactInfo = null;
    resetRoute();
    if (notify) {
      notifyListeners();
    }
  }

  void closePanel() {
    if (!isPanelOpen) return;
    isPanelOpen = false;
    notifyListeners();
  }

  void resetRoute({bool notify = false}) {
    selectedStart = null;
    selectedEnd = null;
    _currentPolyline = null;
    _selectedStartOrigin = null;
    _selectedEndOrigin = null;
    _currentRouteDistanceMeters = null;
    _currentRouteEta = null;
    if (notify) {
      notifyListeners();
    }
  }

  void setRouteData({
    required LatLng start,
    required LatLng end,
    required RoutePointOrigin startOrigin,
    required RoutePointOrigin endOrigin,
    required List<LatLng> polyline,
    double? distanceMeters,
    Duration? duration,
  }) {
    selectedStart = start;
    selectedEnd = end;
    _selectedStartOrigin = startOrigin;
    _selectedEndOrigin = endOrigin;
    _currentPolyline = List<LatLng>.from(polyline);
    _currentRouteDistanceMeters =
        distanceMeters ?? _computePolylineDistanceMeters(_currentPolyline);
    _currentRouteEta =
        duration ?? _estimateEtaFromDistance(_currentRouteDistanceMeters);
    notifyListeners();
  }

  void clearRouteOnly() {
    resetRoute(notify: true);
  }

  void setCommandTab(CommandTab tab) {
    if (_commandTab == tab) return;
    _commandTab = tab;
    if (selectedCommandeId != null) {
      final currentList =
          _commandTab == CommandTab.mes
              ? <Commande>[
                ..._mesCommandes,
                ..._mesCommandesSecours.map((entry) => entry.commande),
              ]
              : _commandes;
      if (!currentList.any((c) => c.id == selectedCommandeId)) {
        clearSelection(notify: false);
      }
    }
    notifyListeners();
  }

  /// Lance/relance le timer silencieux.
  void _ensureAutoRefreshTimer() {
    _refreshTimer?.cancel();
    if (_currentZone == null) return; // pas de zone -> pas de timer
    _refreshTimer = Timer.periodic(autoRefreshEvery, (_) {
      // re-fetch invisible
      refreshByZone(_currentZone!, silent: true);
    });
  }

  /// À appeler quand la zone détectée change OU au premier démarrage.
  Future<void> setZoneAndRefresh(String zone, {bool silent = false}) async {
    if (_currentZone == zone) {
      await refreshByZone(zone, silent: silent);
      return;
    }
    _currentZone = zone;
    _ensureAutoRefreshTimer();
    await refreshByZone(zone, silent: silent);
  }

  /// Appelle le backend: POST /commandes/sous-zones/vehicule
  Future<void> refreshByZone(String zone, {bool silent = false}) async {
    try {
      final service = CommandeService(Api());
      final user = _authController.currentUser.value;
      final isIndisponible = isCurrentTransporteurIndisponible;
      final vehicule = user?.typeVehicule?.name;
      if (vehicule == null || vehicule.isEmpty) {
        throw Exception(
          'Type vehicule introuvable pour l\'utilisateur courant',
        );
      }
      final zoneDepart = user?.zoneDepart ?? const <String, List<String>>{};
      final zoneArriver = user?.zoneArriver ?? const <String, List<String>>{};
      final sousZonesDepart = zoneDepart.values.expand((z) => z).toList();
      final sousZonesArrivee = zoneArriver.values.expand((z) => z).toList();
      final bool hasSousZones =
          sousZonesDepart.isNotEmpty && sousZonesArrivee.isNotEmpty;
      List<Commande> list;
      if (isIndisponible) {
        final transporteurId = user?.id;
        if (transporteurId == null || transporteurId.isEmpty) {
          throw Exception('Transporteur courant introuvable');
        }
        final mes = await service.getCommandesNonLivreesByTransporteur(
          transporteurId,
        );
        _mesCommandes
          ..clear()
          ..addAll(mes);
        list = _mesCommandes
            .where(
              (commande) =>
                  (commande.transporteurSecoursId ?? '').trim().isEmpty,
            )
            .toList(growable: false);
      } else {
        list =
            hasSousZones
                ? await service.getBySousZonesAndVehicule(
                  sousZonesDepart: sousZonesDepart,
                  sousZonesArrivee: sousZonesArrivee,
                  vehicule: vehicule,
                )
                : await service.getByZoneAndVehicule(
                  zone: zone,
                  vehicule: vehicule,
                );
      }
      List<TransporteurPanneCommandesResponse> transporteursEnPanne =
          const <TransporteurPanneCommandesResponse>[];
      List<TransporteurSecoursCommandesResponse> transporteursSecours =
          const <TransporteurSecoursCommandesResponse>[];
      List<CommandeTransporteurPrincipalResponse> mesCommandesSecours =
          const <CommandeTransporteurPrincipalResponse>[];
      try {
        if (isIndisponible) {
          final transporteurId = user?.id;
          if (transporteurId != null && transporteurId.isNotEmpty) {
            transporteursSecours = await service
                .getTransporteursSecoursAvecCommandes(transporteurId);
          }
        } else {
          transporteursEnPanne =
              await service.getTransporteursEnPanneAvecCommandes();
        }
      } catch (e) {
        debugPrint('secours/panne refresh failed: $e');
      }

      final transporteurId = _authController.currentUser.value?.id;
      if (!isIndisponible &&
          transporteurId != null &&
          transporteurId.isNotEmpty) {
        final mes = await service.getCommandesNonLivreesByTransporteur(
          transporteurId,
        );
        try {
          mesCommandesSecours = await service
              .getCommandesEnRouteByTransporteurSecours(transporteurId);
        } catch (e) {
          debugPrint('mes commandes secours refresh failed: $e');
          mesCommandesSecours = const <CommandeTransporteurPrincipalResponse>[];
        }
        _mesCommandes
          ..clear()
          ..addAll(mes);
        if (list.isNotEmpty) {
          final entries = await Future.wait(
            list.map((commande) async {
              try {
                final ids = await service.getTransporteursMinCommandes(
                  commande.id,
                );
                return MapEntry(commande.id, ids.contains(transporteurId));
              } catch (_) {
                return MapEntry(commande.id, false);
              }
            }),
          );
          _minTransporteursByCommandeId = {
            for (final entry in entries) entry.key: entry.value,
          };
        } else {
          _minTransporteursByCommandeId = {};
        }
      } else if (!isIndisponible) {
        _mesCommandes.clear();
        _mesCommandesSecours.clear();
        _minTransporteursByCommandeId = {};
      }

      // LOG CONSOLE UNIQUEMENT
      debugPrint(
        '---- [REFRESH] Commandes pour zone $zone : ${list.length} ----',
      );
      for (final c in list) {
        debugPrint(
          'Commande ${c.id} | depart=${c.zonePrincipaleDepart} | arrivee=${c.zonePrincipaleArrivee}',
        );
      }

      _commandes
        ..clear()
        ..addAll(list);
      _mesCommandesSecours
        ..clear()
        ..addAll(mesCommandesSecours);
      _transporteursEnPanne
        ..clear()
        ..addAll(transporteursEnPanne);
      _transporteursSecours
        ..clear()
        ..addAll(transporteursSecours);

      if (silent) {
        // Silent mode: keep data without resetting visible UI state.
      }

      _syncSelectedSecoursContactAfterRefresh();
      _handleSelectionAfterRefresh();

      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ refreshByZone($zone) failed: $e');
    }
  }

  void moveToMesCommandes(Commande commande) {
    _commandes.removeWhere((c) => c.id == commande.id);
    _removeCommandeFromPanneList(commande.id);
    final exists = _mesCommandes.any((c) => c.id == commande.id);
    if (!exists) {
      _mesCommandes.add(commande);
    } else {
      updateCommande(commande);
      return;
    }
    notifyListeners();
  }

  void _removeCommandeFromPanneList(String commandeId) {
    final updatedEntries = <TransporteurPanneCommandesResponse>[];
    for (final entry in _transporteursEnPanne) {
      final filteredCommandes =
          entry.commandes
              .where((commandeEntry) => commandeEntry.commande.id != commandeId)
              .toList();
      if (filteredCommandes.isEmpty) {
        continue;
      }
      updatedEntries.add(
        TransporteurPanneCommandesResponse(
          transporteur: entry.transporteur,
          commandes: filteredCommandes,
        ),
      );
    }
    _transporteursEnPanne
      ..clear()
      ..addAll(updatedEntries);
  }

  Commande? _findCommandeById(String? id) {
    if (id == null) return null;
    for (final c in _commandes) {
      if (c.id == id) {
        return c;
      }
    }
    for (final c in _mesCommandes) {
      if (c.id == id) {
        return c;
      }
    }
    for (final entry in _mesCommandesSecours) {
      if (entry.commande.id == id) {
        return entry.commande;
      }
    }
    return null;
  }

  void _syncSelectedSecoursContactAfterRefresh() {
    final id = selectedCommandeId;
    if (id == null) return;
    final nextInfo = buildSecoursContactInfoForCommande(id);
    if (nextInfo == null) return;
    final previousInfo = _selectedContactInfo;
    final bool routeChanged =
        previousInfo == null ||
        previousInfo.routeStartLatitude != nextInfo.routeStartLatitude ||
        previousInfo.routeStartLongitude != nextInfo.routeStartLongitude ||
        previousInfo.routeTargetLatitude != nextInfo.routeTargetLatitude ||
        previousInfo.routeTargetLongitude != nextInfo.routeTargetLongitude;
    _selectedContactInfo = nextInfo;
    if (routeChanged) {
      resetRoute();
    }
  }

  void _handleSelectionAfterRefresh() {
    final id = selectedCommandeId;
    if (id == null) return;
    final commande = _findCommandeById(id);
    if (commande == null && _selectedCommandeOverride == null) {
      clearSelection(notify: false);
      return;
    }
    if (commande != null) {
      _selectedCommandeOverride = null;
    }

    if (_didRoutePointsChange(commande ?? _selectedCommandeOverride!)) {
      resetRoute();
    }
  }

  bool _didRoutePointsChange(Commande commande) {
    final startChanged = _didPointChange(
      previous: selectedStart,
      origin: _selectedStartOrigin,
      commande: commande,
    );
    final endChanged = _didPointChange(
      previous: selectedEnd,
      origin: _selectedEndOrigin,
      commande: commande,
    );
    return startChanged || endChanged;
  }

  bool _didPointChange({
    required LatLng? previous,
    required RoutePointOrigin? origin,
    required Commande commande,
  }) {
    if (previous == null || origin == null) {
      return false;
    }
    if (origin == RoutePointOrigin.courier) {
      return false;
    }
    if (origin == RoutePointOrigin.contact) {
      return false;
    }
    final updated = _latLngFromCommande(origin, commande);
    if (updated == null) {
      return true;
    }
    return !_sameLatLng(previous, updated);
  }

  LatLng? _latLngFromCommande(RoutePointOrigin origin, Commande commande) {
    switch (origin) {
      case RoutePointOrigin.depart:
        if (commande.latitudeDepart == null ||
            commande.longitudeDepart == null) {
          return null;
        }
        return LatLng(commande.latitudeDepart!, commande.longitudeDepart!);
      case RoutePointOrigin.destination:
        if (commande.latitudeDestination == null ||
            commande.longitudeDestination == null) {
          return null;
        }
        return LatLng(
          commande.latitudeDestination!,
          commande.longitudeDestination!,
        );
      case RoutePointOrigin.courier:
      case RoutePointOrigin.contact:
        return null;
    }
  }

  bool _sameLatLng(LatLng a, LatLng b) {
    const tolerance = 1e-6;
    return (a.latitude - b.latitude).abs() < tolerance &&
        (a.longitude - b.longitude).abs() < tolerance;
  }

  void updateCommande(Commande updated) {
    final id = updated.id;
    if (id == null) return;
    for (var i = 0; i < _commandes.length; i++) {
      if (_commandes[i].id == id) {
        _commandes[i] = updated;
        notifyListeners();
        return;
      }
    }
    for (var i = 0; i < _mesCommandes.length; i++) {
      if (_mesCommandes[i].id == id) {
        _mesCommandes[i] = updated;
        notifyListeners();
        return;
      }
    }
    for (var i = 0; i < _mesCommandesSecours.length; i++) {
      if (_mesCommandesSecours[i].commande.id == id) {
        final current = _mesCommandesSecours[i];
        _mesCommandesSecours[i] = CommandeTransporteurPrincipalResponse(
          commande: updated,
          produits: current.produits,
          transporteur: current.transporteur,
        );
        notifyListeners();
        return;
      }
    }
  }

  double? _computePolylineDistanceMeters(List<LatLng>? points) {
    if (points == null || points.length < 2) return null;
    double total = 0;
    for (var i = 0; i < points.length - 1; i++) {
      total += _distanceCalculator.as(
        LengthUnit.Meter,
        points[i],
        points[i + 1],
      );
    }
    return total;
  }

  Duration? _estimateEtaFromDistance(double? distanceMeters) {
    if (distanceMeters == null) return null;
    final distanceKm = distanceMeters / 1000;
    if (distanceKm <= 0) return Duration.zero;
    final hours = distanceKm / kAverageCourierSpeedKmh;
    final seconds = (hours * 3600).round();
    return Duration(seconds: seconds < 0 ? 0 : seconds);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
