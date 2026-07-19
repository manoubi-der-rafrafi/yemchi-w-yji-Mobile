import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';

class AuthUserService {
  final Api api;
  AuthUserService(this.api);
  final ValueNotifier<Utilisateur?> currentUser = ValueNotifier(null);

  // ---- Endpoints centralisés ----
  static const _login = '/utilisateur/login';
  static const _me = '/utilisateur/me';
  static const _searchNum = '/utilisateur/search/numero';
  static const _searchEmail = '/utilisateur/search/email';
  static String _byId(String id) => '/utilisateur/id/$id';
  static String _updateById(String id) => '/utilisateur/$id';
  static String _etatIncidentPanne(String id) =>
      '/utilisateur/$id/etat-incident/panne';
  static String _etatIncidentAccident(String id) =>
      '/utilisateur/$id/etat-incident/accident';
  static String _etatIncidentAccidentProduits(String id) =>
      '/utilisateur/$id/etat-incident/accident/produits';
  static String _zonesDepartArriver(String id) =>
      '/utilisateur/$id/zones-depart-arriver';

  // ---- Register endpoints ----
  static const _register = '/utilisateur/register';

  // ---------- REGISTER ----------
  /// Crée un compte complet en une seule requête (POST /api/utilisateur/register).
  /// Retourne un [LoginResult] (token + user) directement utilisable pour connecter l'utilisateur.
  Future<LoginResult> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String adresse,
    required String dateNaissance, // format "YYYY-MM-DD"
  }) async {
    final r = await api.post(
      _register,
      body: json.encode({
        'email': email,
        'motDePasse': password,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'adresse': adresse,
        'dateNaissance': dateNaissance,
      }),
      includeAuth: false,
    );

    final m = json.decode(r.body) as Map<String, dynamic>;

    final token = m['token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException(500, 'Token manquant dans la réponse');
    }

    final userMap =
        (m['user'] is Map<String, dynamic>)
            ? m['user'] as Map<String, dynamic>
            : m;
    final user = Utilisateur.fromJson(userMap);

    return LoginResult(token: token, user: user);
  }

  // ---------- LOGIN ----------
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final r = await api.post(
      _login,
      body: json.encode({'email': email, 'motDePasse': password}),
      includeAuth: false,
    );

    final m = json.decode(r.body) as Map<String, dynamic>;

    final token = m['token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException(500, 'Token manquant dans la réponse');
    }

    final userMap =
        (m['user'] is Map<String, dynamic>)
            ? m['user'] as Map<String, dynamic>
            : m;
    final user = Utilisateur.fromJson(userMap);

    return LoginResult(token: token, user: user);
  }

  // ---------- PROFIL / ME ----------
  Future<Utilisateur> me([String? userId]) async {
    final r = await api.get(userId == null ? _me : '$_me?id=$userId');
    final m = json.decode(r.body);

    final data =
        (m is Map && m['user'] is Map)
            ? m['user'] as Map<String, dynamic>
            : (m as Map<String, dynamic>);

    final user = Utilisateur.fromJson(data);
    currentUser.value = user;
    return user;
  }

  // ---------- GET BY ID ----------
  Future<Utilisateur> getById(String id) async {
    final r = await api.get(_byId(id));
    final m = json.decode(r.body) as Map<String, dynamic>;
    return Utilisateur.fromJson(m);
  }

  Future<Utilisateur> chercherParNumero(String numero) async {
    final r = await api.get('$_searchNum?numero=$numero');
    final m = json.decode(r.body) as Map<String, dynamic>;
    return Utilisateur.fromJson(m);
  }

  Future<Utilisateur> chercherParEmail(String email) async {
    final r = await api.get('$_searchEmail?email=$email');
    final m = json.decode(r.body) as Map<String, dynamic>;
    return Utilisateur.fromJson(m);
  }

  // ---------- UPDATE "ME" (profil courant) ----------
  Future<Utilisateur> updateMe({
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? image,
    // nouveaux champs si tu les exposes dans la page profil :
    Zone? zone,
    SousZone? sousZone,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      if (nom != null) 'nom': nom,
      if (prenom != null) 'prenom': prenom,
      if (adresse != null) 'adresse': adresse,
      if (telephone != null) 'telephone': telephone,
      if (image != null) 'image': image,
      if (zone != null) 'zone': zone.name,
      if (sousZone != null) 'sousZone': sousZone.name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final r = await api.put(_me, body: json.encode(body));
    final m = json.decode(r.body) as Map<String, dynamic>;
    final user = Utilisateur.fromJson(m);
    currentUser.value = user;
    return user;
  }

  // ---------- UPDATE UTILISATEUR PAR ID ----------
  // Utilise le modèle complet et n'envoie que les champs non-nuls (grâce à toJson()).
  Future<Utilisateur> updateUtilisateur(Utilisateur updated) async {
    final body = updated.toJson(includeId: false);

    final r = await api.put(_updateById(updated.id), body: json.encode(body));

    if (r.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(r.body);
      return Utilisateur.fromJson(data);
    } else if (r.statusCode == 400) {
      // ex: latitude/longitude invalides
      // décoder en utf8 si ton Api ne l’a pas déjà fait
      throw ApiException(r.statusCode, r.body);
    } else if (r.statusCode == 404) {
      throw ApiException(r.statusCode, 'Utilisateur non trouvé');
    } else {
      throw ApiException(
        r.statusCode,
        'Échec de mise à jour (${r.statusCode})',
      );
    }
  }

  // ---------- Mises à jour ciblées (exemples pratiques) ----------
  Future<Utilisateur> updateZone({
    required String userId,
    required Zone zone,
  }) async {
    final r = await api.put(
      _updateById(userId),
      body: json.encode({'zone': zone.name}),
    );

    if (r.statusCode == 200) {
      return Utilisateur.fromJson(json.decode(r.body));
    } else {
      throw ApiException(r.statusCode, 'Échec de mise à jour zone');
    }
  }

  Future<Utilisateur> updateSousZone({
    required String userId,
    required SousZone sousZone,
  }) async {
    final r = await api.put(
      _updateById(userId),
      body: json.encode({'sousZone': sousZone.name}),
    );

    if (r.statusCode == 200) {
      return Utilisateur.fromJson(json.decode(r.body));
    } else {
      throw ApiException(r.statusCode, 'Échec de mise à jour sous-zone');
    }
  }

  Future<Utilisateur> updateLocalisation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    final r = await api.put(
      _updateById(userId),
      body: json.encode({'latitude': latitude, 'longitude': longitude}),
    );

    if (r.statusCode == 200) {
      return Utilisateur.fromJson(json.decode(r.body));
    } else if (r.statusCode == 400) {
      throw ApiException(r.statusCode, 'Latitude/Longitude invalides');
    } else {
      throw ApiException(r.statusCode, 'Échec de mise à jour localisation');
    }
  }

  Future<Utilisateur> marquerTransporteurEnPanne(String userId) async {
    final r = await api.put(_etatIncidentPanne(userId), body: json.encode({}));
    return Utilisateur.fromJson(json.decode(r.body));
  }

  Future<Utilisateur> marquerTransporteurEnAccident(String userId) async {
    final r = await api.put(
      _etatIncidentAccident(userId),
      body: json.encode({}),
    );
    return Utilisateur.fromJson(json.decode(r.body));
  }

  Future<Utilisateur> declarerAccidentAvecProduits({
    required String userId,
    required Map<String, int> produitsAffectes,
    required List<String> produitsNonAffectes,
  }) async {
    final r = await api.put(
      _etatIncidentAccidentProduits(userId),
      body: json.encode({
        'produitsAffectes': produitsAffectes,
        'produitsNonAffectes': produitsNonAffectes,
      }),
    );
    return Utilisateur.fromJson(json.decode(r.body));
  }

  Future<Utilisateur> meById(String id) async {
    final r = await api.get('$_me?id=$id');
    final m = json.decode(r.body);

    final data =
        (m is Map && m['user'] is Map)
            ? m['user'] as Map<String, dynamic>
            : (m as Map<String, dynamic>);

    final user = Utilisateur.fromJson(data);
    currentUser.value = user;
    return user;
  }

  Future<Utilisateur> updateZonesDepartArriver({
    required String userId,
    required Map<String, List<String>> zoneDepart,
    required Map<String, List<String>> zoneArriver,
  }) async {
    final r = await api.put(
      _zonesDepartArriver(userId),
      body: json.encode({'zoneDepart': zoneDepart, 'zoneAriver': zoneArriver}),
    );
    return Utilisateur.fromJson(json.decode(r.body));
  }
}

// ---------- DTO résultat de login ----------
class LoginResult {
  final String token;
  final Utilisateur user;
  LoginResult({required this.token, required this.user});
}
