// home_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';

enum AppLang { ar, en }
enum CommandTab { mes, envoyees }
enum RoutePointOrigin { depart, destination, courier }

class HomeController extends ChangeNotifier {
  HomeController(this._authController);

  final AuthController _authController;
  static const double kAverageCourierSpeedKmh = 28;

  AppLang currentLang = AppLang.en;

  // --- ÉTAT COMMANDES & ZONE COURANTE ---
  final List<Commande> _commandes = [];
  final List<Commande> _mesCommandes = [];

  List<Commande> get commandes => List.unmodifiable(_commandes);
  List<Commande> get mesCommandes => List.unmodifiable(_mesCommandes);
  List<Commande> get activeCommandes =>
      _commandTab == CommandTab.mes ? mesCommandes : commandes;

  String? _currentZone; // ex: "GRAND_TUNIS"
  String? get currentZone => _currentZone;

  String? selectedCommandeId;
  bool isPanelOpen = false;
  Commande? get selectedCommande => _findCommandeById(selectedCommandeId);
  bool get isSelectedCommandeMine {
    final id = selectedCommandeId;
    if (id == null) return false;
    return _mesCommandes.any((commande) => commande.id == id);
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
  Duration autoRefreshEvery = const Duration(seconds: 30);

  // --- AUTRES (existant) ---
  final List<Map<String, String>> notifications = [
    {'title': 'Nouvelle commande', 'detail': 'Pickup à 14:30 - Centre ville'},
    {
      'title': 'Mise à jour',
      'detail': 'Commande #124 en attente de validation',
    },
  ];

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
    isPanelOpen = openPanel;
    if (idChanged) {
      resetRoute();
    }
    notifyListeners();
  }

  void clearSelection({bool notify = true}) {
    selectedCommandeId = null;
    isPanelOpen = false;
    resetRoute();
    if (notify) {
      notifyListeners();
    }
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
          _commandTab == CommandTab.mes ? _mesCommandes : _commandes;
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

  /// Appelle le backend: GET /commandes/zone/{zone}
  Future<void> refreshByZone(String zone, {bool silent = false}) async {
    try {
      final service = CommandeService(Api());
      final list = await service.getByZone(zone);

      final transporteurId = _authController.currentUser.value?.id;
      if (transporteurId != null && transporteurId.isNotEmpty) {
        final mes = await service.getCommandesByTransporteur(transporteurId);
        _mesCommandes
          ..clear()
          ..addAll(mes);
      } else {
        _mesCommandes.clear();
      }

      // LOG CONSOLE UNIQUEMENT
      debugPrint('---- [REFRESH] Commandes pour zone $zone : ${list.length} ----');
      for (final c in list) {
        debugPrint(
          'Commande ${c.id} | depart=${c.zonePrincipaleDepart} | arrivee=${c.zonePrincipaleArrivee}',
        );
      }

      _commandes
        ..clear()
        ..addAll(list);

      if (silent) {
      // Silent mode: keep data without resetting visible UI state.
      }

      _handleSelectionAfterRefresh();

      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ refreshByZone($zone) failed: $e');
    }
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
    return null;
  }

  void _handleSelectionAfterRefresh() {
    final id = selectedCommandeId;
    if (id == null) return;
    final commande = _findCommandeById(id);
    if (commande == null) {
      clearSelection(notify: false);
      return;
    }

    if (_didRoutePointsChange(commande)) {
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
        return null;
    }
  }

  bool _sameLatLng(LatLng a, LatLng b) {
    const tolerance = 1e-6;
    return (a.latitude - b.latitude).abs() < tolerance &&
        (a.longitude - b.longitude).abs() < tolerance;
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
