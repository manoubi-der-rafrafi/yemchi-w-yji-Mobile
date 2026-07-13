import 'package:flutter/foundation.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/core/storage/token_storage.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';

class AuthController {
  AuthController(this._svc);

  final AuthUserService _svc;

  // État observable par l’UI
  final ValueNotifier<Utilisateur?> currentUser = ValueNotifier(null);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  /// Register: crée le compte puis connecte automatiquement.
  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String adresse,
    required String dateNaissance,
  }) async {
    loading.value = true;
    error.value = null;
    try {
      final res = await _svc.register(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        adresse: adresse,
        dateNaissance: dateNaissance,
      );
      await TokenStorage.save(access: res.token, userId: res.user.id);
      currentUser.value = res.user;
      return true;
    } on ApiException catch (e) {
      error.value = e.message;
      return false;
    } catch (e) {
      // TimeoutException, SocketException, etc.
      final msg = e.toString();
      if (msg.contains('TimeoutException') || msg.contains('timeout')) {
        error.value = 'Serveur injoignable. Vérifiez votre connexion.';
      } else if (msg.contains('SocketException') || msg.contains('Connection refused')) {
        error.value = 'Impossible de contacter le serveur. Est-il démarré ?';
      } else {
        error.value = msg;
      }
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// Login: récupère {token, user}, sauvegarde le token, met à jour l'état.
  Future<bool> login(String email, String password) async {
    loading.value = true; error.value = null;
    try {
      final res = await _svc.login(email: email, password: password);
      await TokenStorage.save(access: res.token, userId: res.user.id);
      currentUser.value = res.user;
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// Si un token existe déjà, tenter /me pour restaurer la session.
  Future<void> loadMeIfToken() async {
    if (!await TokenStorage.hasAccess()) return;

    final storedUserId = await TokenStorage.userId();
    if (storedUserId != null && storedUserId.isNotEmpty) {
      final user = await fetchUserById(storedUserId);
      if (user != null) return;
    }

    try {
      currentUser.value = await _svc.me();
    } catch (_) {}
  }

  /// Mettre à jour mon profil (PUT /me) puis rafraîchir l'état courant.
  Future<bool> updateMe({
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? image,
    Zone? zone,
    SousZone? sousZone,
    double? latitude,
    double? longitude,
  }) async {
    loading.value = true; error.value = null;
    try {
      final u = await _svc.updateMe(
        nom: nom,
        prenom: prenom,
        adresse: adresse,
        telephone: telephone,
        image: image,
        zone: zone,
        sousZone: sousZone,
        latitude: latitude,
        longitude: longitude,
      );
      currentUser.value = u;
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// 🆕 Mise à jour complète d'un utilisateur (via toJson)
  Future<bool> updateUtilisateur(Utilisateur updated) async {
    loading.value = true; error.value = null;
    try {
      final u = await _svc.updateUtilisateur(updated);
      currentUser.value = u;
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// 🆕 Mettre à jour uniquement la zone
  Future<bool> updateZone(Zone zone) async {
    if (currentUser.value == null) return false;
    loading.value = true; error.value = null;
    try {
      final u = await _svc.updateZone(
        userId: currentUser.value!.id,
        zone: zone,
      );
      //currentUser.value = u;
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// 🆕 Mettre à jour uniquement la sous-zone
  Future<bool> updateSousZone(SousZone sousZone) async {
    
    if (currentUser.value == null) return false;
    loading.value = true; error.value = null;
    try {
      final u = await _svc.updateSousZone(
        userId: currentUser.value!.id,
        sousZone: sousZone,
      );
     // currentUser.value = u;
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// 🆕 Mettre à jour la position GPS (latitude, longitude)
  Future<bool> updateLocalisation({
    required double latitude,
    required double longitude,
  }) async {
    if (currentUser.value == null) return false;
    loading.value = true; error.value = null;
    try {
      final u = await _svc.updateLocalisation(
        userId: currentUser.value!.id,
        latitude: latitude,
        longitude: longitude,
      );
      // currentUser.value = u;
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// Logout: efface les tokens et l'utilisateur courant.
  Future<void> logout() async {
    await TokenStorage.clear();
    currentUser.value = null;
  }
  Future<Utilisateur?> fetchUserById(String id) async {
    loading.value = true;
    error.value = null;
    try {
      final user = await _svc.meById(id);
      currentUser.value = user;
      return user;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      loading.value = false;
    }
  }
}
