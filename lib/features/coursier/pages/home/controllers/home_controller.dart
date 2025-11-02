// home_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/auth/controllers/auth_controller.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';

enum AppLang { ar, en }
enum CommandTab { mes, envoyees }

class HomeController extends ChangeNotifier {
  HomeController(this._authController);

  final AuthController _authController;

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

  Commande? _selectedCommande;
  Commande? get selectedCommande => _selectedCommande;

  CommandTab _commandTab = CommandTab.mes;
  CommandTab get commandTab => _commandTab;

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

  void selectCommande(Commande? commande) {
    _selectedCommande = commande;
    notifyListeners();
  }

  void setCommandTab(CommandTab tab) {
    if (_commandTab == tab) return;
    _commandTab = tab;
    if (_selectedCommande != null) {
      final currentList =
          _commandTab == CommandTab.mes ? _mesCommandes : _commandes;
      if (!currentList.any((c) => c.id == _selectedCommande!.id)) {
        _selectedCommande = null;
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

      if (_selectedCommande != null &&
          !_commandes.any((c) => c.id == _selectedCommande!.id)) {
        _selectedCommande = null;
      }

      if (!silent) {
        notifyListeners();
        return;
      }

      // Mode silencieux : pas de feedback UI, mais on force quand même un rebuild.
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ refreshByZone($zone) failed: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
