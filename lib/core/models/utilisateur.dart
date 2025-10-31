// lib/core/models/utilisateur.dart
import 'dart:convert';

class Utilisateur {
  // Identité
  final String id;

  // Infos perso
  final String? nom;
  final String? prenom;
  final DateTime? dateNaissance;

  // Auth / contact
  final String? email;
  final String? telephone;

  // Métadonnées de rôle / statut
  final Role role;
  final Statut statut;

  // Adresse / image
  final String? adresse;
  final String? image;

  // Connexion / timestamps
  final DateTime? dateCreation;
  final DateTime? lastSeen;
  final bool? online;

  // ✅ Nouveaux attributs alignés backend
  final double? latitude;     // Java: Double
  final double? longitude;    // Java: Double
  final SousZone? sousZone;   // Java: enum SousZone
  final Zone? zone;           // Java: enum Zone

  const Utilisateur({
    required this.id,
    this.nom,
    this.prenom,
    this.dateNaissance,
    this.email,
    this.telephone,
    this.role = Role.client,
    this.statut = Statut.actif,
    this.adresse,
    this.image,
    this.dateCreation,
    this.lastSeen,
    this.online,
    this.latitude,
    this.longitude,
    this.sousZone,
    this.zone,
  });

  /// copyWith pour mises à jour immutables
  Utilisateur copyWith({
    String? id,
    String? nom,
    String? prenom,
    DateTime? dateNaissance,
    String? email,
    String? telephone,
    Role? role,
    Statut? statut,
    String? adresse,
    String? image,
    DateTime? dateCreation,
    DateTime? lastSeen,
    bool? online,
    double? latitude,
    double? longitude,
    SousZone? sousZone,
    Zone? zone,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      adresse: adresse ?? this.adresse,
      image: image ?? this.image,
      dateCreation: dateCreation ?? this.dateCreation,
      lastSeen: lastSeen ?? this.lastSeen,
      online: online ?? this.online,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sousZone: sousZone ?? this.sousZone,
      zone: zone ?? this.zone,
    );
  }

  // ---------------- JSON MAPPING ----------------

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String && v.trim().isNotEmpty) return double.tryParse(v.trim());
      return null;
    }

    return Utilisateur(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      dateNaissance: _parseDate(json['dateNaissance']),
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
      role: _roleFromString(json['role']),
      statut: _statutFromString(json['statut']),
      adresse: json['adresse'] as String?,
      image: json['image'] as String?,
      dateCreation: _parseDate(json['dateCreation']),
      lastSeen: _parseDate(json['lastSeen']),
      online: json['online'] as bool?,
      // ✅ nouveaux champs
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      sousZone: _sousZoneFromString(json['sousZone']),
      zone: _zoneFromString(json['zone']),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    String? _dateToIso(DateTime? d) => d?.toIso8601String();

    final map = <String, dynamic>{
      if (includeId) 'id': id,
      'nom': nom,
      'prenom': prenom,
      'dateNaissance': _dateToIso(dateNaissance),
      'email': email,
      'telephone': telephone,
      'role': role.name,       // "client" | "transporteur" | "admin"
      'statut': statut.name,   // "actif"  | "inactif"      | "banni"
      'adresse': adresse,
      'image': image,
      'dateCreation': _dateToIso(dateCreation),
      'lastSeen': _dateToIso(lastSeen),
      'online': online,
      // ✅ nouveaux champs
      'latitude': latitude,
      'longitude': longitude,
      'sousZone': sousZone?.name,
      'zone': zone?.name,
    };

    // n’envoie pas les null (pratique pour PUT partiel)
    map.removeWhere((_, v) => v == null);
    return map;
  }

  // pour debug / logs
  factory Utilisateur.fromJsonString(String source) =>
      Utilisateur.fromJson(jsonDecode(source) as Map<String, dynamic>);
  String toJsonString({bool includeId = true}) =>
      jsonEncode(toJson(includeId: includeId));

  @override
  String toString() =>
      'Utilisateur(id: $id, nom: $nom, prenom: $prenom, email: $email, '
      'role: ${role.name}, statut: ${statut.name}, '
      'lat: $latitude, lng: $longitude, sousZone: ${sousZone?.name}, zone: ${zone?.name})';

  // ---------------- ENUM HELPERS ----------------

  static Role _roleFromString(dynamic v) {
    final s = (v ?? '').toString().toLowerCase();
    switch (s) {
      case 'transporteur':
        return Role.transporteur;
      case 'admin':
        return Role.admin;
      case 'client':
      default:
        return Role.client;
    }
  }

  static Statut _statutFromString(dynamic v) {
    final s = (v ?? '').toString().toLowerCase();
    switch (s) {
      case 'inactif':
        return Statut.inactif;
      case 'banni':
        return Statut.banni;
      case 'actif':
      default:
        return Statut.actif;
    }
  }

  static Zone? _zoneFromString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().toUpperCase();
    return Zone.values.firstWhere(
      (z) => z.name.toUpperCase() == s,
      orElse: () => Zone.GRAND_TUNIS,
    );
  }

  static SousZone? _sousZoneFromString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().toUpperCase();
    return SousZone.values.firstWhere(
      (sz) => sz.name.toUpperCase() == s,
      orElse: () => SousZone.TUNIS_CENTRE,
    );
  }
}

// ---------------- ENUMS ----------------

enum Role { client, transporteur, admin }
enum Statut { actif, inactif, banni }

// --- Enum pour les grandes zones (régions principales) ---
enum Zone {
  GRAND_TUNIS,
  COTIER_NORD,
  CENTRE_EST,
  SFAX,
  SUD_EST,
  INTERIEUR,
}

// --- Enum pour les sous-zones (zones détaillées pour scooters) ---
enum SousZone {
  // Grand Tunis
  TUNIS_CENTRE,
  ARIANA_NORD,
  BEN_AROUS_SUD,
  MANOUBA_OUEST,

  // Côtier Nord
  BIZERTE_METRO,
  NABEUL_HAMMAMET,
  KELIBIA_MENZEL_TEMIME,

  // Centre Est
  SOUSSE,
  MONASTIR,
  MAHDIA,

  // Sfax
  SFAX,

  // Sud Est
  GABES,
  DJERBA_ZARZIS,

  // Intérieur
  KAIROUAN,
}
