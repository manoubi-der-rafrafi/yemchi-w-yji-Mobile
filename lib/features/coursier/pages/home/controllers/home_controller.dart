// home_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // si déjà utilisé ailleurs
import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/features/commande/data/commande_service.dart';
import 'package:yemchi_wyji/core/network/api.dart';

enum AppLang { ar, en }

class HomeController extends ChangeNotifier {
  AppLang currentLang = AppLang.en;

  // --- ÉTAT COMMANDES & ZONE COURANTE ---
  final List<Commande> _commandes = [];
  List<Commande> get commandes => List.unmodifiable(_commandes);

  String? _currentZone; // ex: "GRAND_TUNIS"
  String? get currentZone => _currentZone;
  Commande? _selectedCommande;
  Commande? get selectedCommande => _selectedCommande;

  // --- RAFRAÎCHISSEMENT AUTO ---
  Timer? _refreshTimer;
  Duration autoRefreshEvery = const Duration(
    seconds: 30,
  ); // règle l’intervalle ici

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

  /// Lance/relance le timer silencieux
  void _ensureAutoRefreshTimer() {
    _refreshTimer?.cancel();
    if (_currentZone == null) return; // pas de zone -> pas de timer
    _refreshTimer = Timer.periodic(autoRefreshEvery, (_) {
      // re-fetch invisible
      refreshByZone(_currentZone!, silent: true);
    });
  }

  /// À appeler quand la zone détectée change OU au premier démarrage
  Future<void> setZoneAndRefresh(String zone, {bool silent = false}) async {
    if (_currentZone == zone) {
      // même zone: on peut décider de forcer un fetch quand même si besoin
      await refreshByZone(zone, silent: silent);
      return;
    }
    _currentZone = zone;
    _ensureAutoRefreshTimer();
    await refreshByZone(zone, silent: silent);
  }

  /// Appelle le backend: GET /commandes/zone/{zone}
  // home_controller.dart
  Future<void> refreshByZone(String zone, {bool silent = false}) async {
    try {
      final service = CommandeService(Api());
      final list = await service.getByZone(zone);

      // 👉 LOG CONSOLE UNIQUEMENT
      print('---- [REFRESH] Commandes pour zone $zone : ${list.length} ----');
      for (final c in list) {
        print(
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

      // Pas de loader/snackbar => on peut même ne PAS notifier si tu veux rester 100% invisible
      if (!silent) {
        notifyListeners();
        return;
      }

      // Mode silencieux : pas de feedback UI, mais on force quand même un rebuild pour la carte/listes.
      notifyListeners();
    } catch (e) {
      print('❌ refreshByZone($zone) failed: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
