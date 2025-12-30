import 'dart:convert';
import 'dart:io'; // Needed for File
import 'package:http/http.dart' as http; // Needed for MultipartRequest
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:flutter/foundation.dart';



class AuthUserService {
  final Api api;
  AuthUserService(this.api);
  final ValueNotifier<Utilisateur?> currentUser = ValueNotifier(null);


  // ---- Endpoints centralisés ----
  static const _login = '/utilisateur/login';
  static const _register = '/utilisateur/register'; // Added
  static const _upload = '/utilisateur/upload';     // Added
  static const _searchNum = '/utilisateur/search/numero'; // Added
  static const _searchEmail = '/utilisateur/search/email'; // Added
  static const _me    = '/utilisateur/me';
  
  static String _byId(String id) => '/utilisateur/id/$id';
  static String _updateById(String id) => '/utilisateur/$id';
  static String _statusById(String id) => '/utilisateur/$id/status'; // Added

  // ---------- LOGIN ----------
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final r = await api.post(
      _login,
      body: json.encode({'email': email, 'motDePasse': password}),
    );

    return _parseAuthResponse(r);
  }

  // ---------- REGISTER (Added) ----------
  /// Registers a new user. Accepts a Map of user data (nom, prenom, email, etc.)
  Future<LoginResult> register(Map<String, dynamic> userData) async {
    final r = await api.post(
      _register,
      body: json.encode(userData),
    );

    return _parseAuthResponse(r);
  }

  // ---------- HELPER: Parse Auth Response ----------
  /// Refactored to avoid code duplication between Login and Register
  LoginResult _parseAuthResponse(http.Response r) {
    final m = json.decode(r.body) as Map<String, dynamic>;

    // Handle cases where token might be 'token' or 'accessToken' based on TS code
    final token = m['token']?.toString() ?? m['accessToken']?.toString();
    
    if (token == null || token.isEmpty) {
      throw ApiException(500, 'Token manquant dans la réponse');
    }

    final userMap = (m['user'] is Map<String, dynamic>)
        ? m['user'] as Map<String, dynamic>
        : m;
    final user = Utilisateur.fromJson(userMap);

    return LoginResult(token: token, user: user);
  }

  // ---------- UPLOAD IMAGE (Added) ----------
  /// Uploads a profile image using MultipartRequest
  /*Future<String> uploadImageProfil(File imageFile) async {
    // Note: We need the base URL from the Api class. 
    // Assuming api.baseUrl exists or constructing it manually.
    // If your Api class doesn't expose baseUrl, replace this with your environment url.
    final uri = Uri.parse('${api.baseUrl}$_upload'); 

    final request = http.MultipartRequest('POST', uri);
    
    // Add headers (Authorization) if needed. 
    // Usually the API wrapper handles this, but for Multipart we often do it manually 
    // unless your Api class has a upload method.
    if (api.token != null) {
      request.headers['Authorization'] = 'Bearer ${api.token}';
    }

    // Add the file
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      // TS Backend returns: { success: boolean; url?: string; message: string }
      return data['url'] as String? ?? '';
    } else {
      throw ApiException(response.statusCode, 'Echec de l\'upload de l\'image');
    }
  }*/

  // ---------- SEARCH (Added) ----------
  
  Future<Utilisateur> chercherParNumero(String numero) async {
    // Uses query parameter ?numero=xxxx
    final r = await api.get('$_searchNum?numero=$numero');
    final m = json.decode(r.body) as Map<String, dynamic>;
    return Utilisateur.fromJson(m);
  }

  Future<Utilisateur> chercherParEmail(String email) async {
    // Uses query parameter ?email=xxxx
    final r = await api.get('$_searchEmail?email=$email');
    final m = json.decode(r.body) as Map<String, dynamic>;
    return Utilisateur.fromJson(m);
  }

  // ---------- STATUS / BEACON (Added) ----------
  
  /// Equivalent to leaveAppBeacon. Updates the user status (e.g. 'inactif').
  Future<void> updateStatus(String userId, String status) async {
    await api.post( // TS uses sendBeacon which is POST, but typically updates are PUT. Stick to POST if TS implies generic body.
      _statusById(userId),
      body: json.encode({'statut': status}),
    );
    // Return void as we just want to fire and forget or await success
  }

  // ---------- PROFIL / ME ----------
   Future<Utilisateur> me(String userId) async { 

    // Your backend sends: .claim("uid", user.getId())

    if (userId == null) {
      throw ApiException(400, 'Impossible de trouver l\'ID utilisateur dans le token');
    }

    // 3. Send the ID as a query parameter (?id=...)
    final r = await api.get('$_me?id=$userId');

    // 4. Parse the response
    final m = json.decode(r.body);
    
    // Handle both direct object or { "user": ... } wrapper
    final data = (m is Map && m.containsKey('user'))
        ? m['user'] as Map<String, dynamic>
        : m as Map<String, dynamic>;

    return Utilisateur.fromJson(data);
  }

  // ---------- GET BY ID ----------
  Future<Utilisateur> getById(String id) async {
    final r = await api.get(_byId(id));
    final m = json.decode(r.body) as Map<String, dynamic>;
    return Utilisateur.fromJson(m);
  }

  // ---------- UPDATE "ME" (profil courant) ----------
  Future<Utilisateur> updateMe({
  required String id, // <--- Add ID here
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
  final body = <String, dynamic>{
    if (nom != null) 'nom': nom,
    if (prenom != null) 'prenom': prenom,
    if (adresse != null) 'adresse': adresse,
    if (telephone != null) 'telephone': telephone,
    if (image != null) 'image': image,
    // Ensure Enums are sent in UPPERCASE if Java expects it
    if (zone != null) 'zone': zone.name.toUpperCase(), 
    if (sousZone != null) 'sousZone': sousZone.name.toUpperCase(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  // Use _updateById instead of _me
  final r = await api.put(_updateById(id), body: json.encode(body)); 
  
  if (r.statusCode == 200) {
    final m = json.decode(r.body) as Map<String, dynamic>;
    return Utilisateur.fromJson(m);
  } else {
    throw ApiException(r.statusCode, r.body);
  }
}
  // ---------- UPDATE UTILISATEUR PAR ID ----------
  Future<Utilisateur> updateUtilisateur(Utilisateur updated) async {
    final body = updated.toJson(includeId: false);

    final r = await api.put(
      _updateById(updated.id),
      body: json.encode(body),
    );

    if (r.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(r.body);
      return Utilisateur.fromJson(data);
    } else if (r.statusCode == 400) {
      throw ApiException(r.statusCode, r.body);
    } else if (r.statusCode == 404) {
      throw ApiException(r.statusCode, 'Utilisateur non trouvé');
    } else {
      throw ApiException(r.statusCode, 'Échec de mise à jour (${r.statusCode})');
    }
  }

  // ---------- Mises à jour ciblées ----------
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
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (r.statusCode == 200) {
      return Utilisateur.fromJson(json.decode(r.body));
    } else if (r.statusCode == 400) {
      throw ApiException(r.statusCode, 'Latitude/Longitude invalides');
    } else {
      throw ApiException(r.statusCode, 'Échec de mise à jour localisation');
    }
  }

  Future<Utilisateur> meById(String id) async {
    final r = await api.get('$_me?id=$id');
    final m = json.decode(r.body);

    final data = (m is Map && m['user'] is Map)
        ? m['user'] as Map<String, dynamic>
        : (m as Map<String, dynamic>);

    return Utilisateur.fromJson(data);
  }
}

// ---------- DTO résultat de login ----------
class LoginResult {
  final String token;
  final Utilisateur user;
  LoginResult({required this.token, required this.user});
}