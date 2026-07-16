// lib/core/models/utilisateur.dart
import 'dart:convert';

class Utilisateur {
  // Identité
  final String id;

  // Infos perso
  final String? nom;
  final String? prenom;
  final DateTime? dateNaissance;
  final String? identifiant;

  // Auth / contact
  final String? email;
  final String? telephone;

  // Métadonnées de rôle / statut
  final Role role;
  final Statut statut;
  final EtatIncident etatIncident;

  // Adresse / image
  final String? adresse;
  final String? image;
  final String? imageCarteIdentiteFace;
  final String? imageCarteIdentiteArriere;
  final String? imagePermis;
  final String? imageCarteGrise;
  final String? imageAssurance;
  final TypeVehicule? typeVehicule;

  // Connexion / timestamps
  final DateTime? dateCreation;
  final DateTime? lastSeen;
  final bool? online;

  // ✅ Nouveaux attributs alignés backend
  final double? latitude;     // Java: Double
  final double? longitude;    // Java: Double
  final SousZone? sousZone;   // Java: enum SousZone
  final Zone? zone;           // Java: enum Zone
  final Map<String, List<String>>? zoneDepart;
  final Map<String, List<String>>? zoneArriver;

  const Utilisateur({
    required this.id,
    this.nom,
    this.prenom,
    this.dateNaissance,
    this.identifiant,
    this.email,
    this.telephone,
    required this.role,
    this.statut = Statut.actif,
    this.etatIncident = EtatIncident.RIEN,
    this.adresse,
    this.image,
    this.imageCarteIdentiteFace,
    this.imageCarteIdentiteArriere,
    this.imagePermis,
    this.imageCarteGrise,
    this.imageAssurance,
    this.typeVehicule,
    this.dateCreation,
    this.lastSeen,
    this.online,
    this.latitude,
    this.longitude,
    this.sousZone,
    this.zone,
    this.zoneDepart,
    this.zoneArriver,
  });

  /// copyWith pour mises à jour immutables
  Utilisateur copyWith({
    String? id,
    String? nom,
    String? prenom,
    DateTime? dateNaissance,
    String? identifiant,
    String? email,
    String? telephone,
    Role? role,
    Statut? statut,
    EtatIncident? etatIncident,
    String? adresse,
    String? image,
    String? imageCarteIdentiteFace,
    String? imageCarteIdentiteArriere,
    String? imagePermis,
    String? imageCarteGrise,
    String? imageAssurance,
    TypeVehicule? typeVehicule,
    DateTime? dateCreation,
    DateTime? lastSeen,
    bool? online,
    double? latitude,
    double? longitude,
    SousZone? sousZone,
    Zone? zone,
    Map<String, List<String>>? zoneDepart,
    Map<String, List<String>>? zoneArriver,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      identifiant: identifiant ?? this.identifiant,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      etatIncident: etatIncident ?? this.etatIncident,
      adresse: adresse ?? this.adresse,
      image: image ?? this.image,
      imageCarteIdentiteFace:
          imageCarteIdentiteFace ?? this.imageCarteIdentiteFace,
      imageCarteIdentiteArriere:
          imageCarteIdentiteArriere ?? this.imageCarteIdentiteArriere,
      imagePermis: imagePermis ?? this.imagePermis,
      imageCarteGrise: imageCarteGrise ?? this.imageCarteGrise,
      imageAssurance: imageAssurance ?? this.imageAssurance,
      typeVehicule: typeVehicule ?? this.typeVehicule,
      dateCreation: dateCreation ?? this.dateCreation,
      lastSeen: lastSeen ?? this.lastSeen,
      online: online ?? this.online,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sousZone: sousZone ?? this.sousZone,
      zone: zone ?? this.zone,
      zoneDepart: zoneDepart ?? this.zoneDepart,
      zoneArriver: zoneArriver ?? this.zoneArriver,
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
      identifiant: json['identifiant'] as String?,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
      role: _roleFromString(json['role']),
      statut: _statutFromString(json['statut']),
      etatIncident: _etatIncidentFromString(json['etatIncident']),
      adresse: json['adresse'] as String?,
      image: json['image'] as String?,
      imageCarteIdentiteFace: json['imageCarteIdentiteFace'] as String?,
      imageCarteIdentiteArriere: json['imageCarteIdentiteArriere'] as String?,
      imagePermis: json['imagePermis'] as String?,
      imageCarteGrise: json['imageCarteGrise'] as String?,
      imageAssurance: json['imageAssurance'] as String?,
      typeVehicule: _typeVehiculeFromString(json['typeVehicule']),
      dateCreation: _parseDate(json['dateCreation']),
      lastSeen: _parseDate(json['lastSeen']),
      online: json['online'] as bool?,
      // ✅ nouveaux champs
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      sousZone: _sousZoneFromString(json['sousZone']),
      zone: _zoneFromString(json['zone']),
      zoneDepart: _parseZoneMap(json['zoneDepart']),
      zoneArriver:
          _parseZoneMap(json['zoneArriver'] ?? json['zoneAriver']),
    );
  }

  static Map<String, List<String>>? _parseZoneMap(dynamic raw) {
    if (raw is! Map) return null;
    final result = <String, List<String>>{};
    raw.forEach((key, value) {
      final zoneKey = key?.toString();
      if (zoneKey == null || zoneKey.isEmpty) return;
      if (value is List) {
        result[zoneKey] = value.map((e) => e.toString()).toList();
      }
    });
    return result.isEmpty ? null : result;
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    String? _dateToIso(DateTime? d) => d?.toIso8601String();

    final map = <String, dynamic>{
      if (includeId) 'id': id,
      'nom': nom,
      'prenom': prenom,
      'dateNaissance': _dateToIso(dateNaissance),
      'identifiant': identifiant,
      'email': email,
      'telephone': telephone,
      'role': role.name,       // "client" | "transporteur" | "admin"
      'statut': statut.name,   // "actif"  | "inactif"      | "banni"
      'etatIncident': etatIncident.name,
      'adresse': adresse,
      'image': image,
      'imageCarteIdentiteFace': imageCarteIdentiteFace,
      'imageCarteIdentiteArriere': imageCarteIdentiteArriere,
      'imagePermis': imagePermis,
      'imageCarteGrise': imageCarteGrise,
      'imageAssurance': imageAssurance,
      'typeVehicule': typeVehicule?.name,
      'dateCreation': _dateToIso(dateCreation),
      'lastSeen': _dateToIso(lastSeen),
      'online': online,
      // ✅ nouveaux champs
      'latitude': latitude,
      'longitude': longitude,
      'sousZone': sousZone?.name,
      'zone': zone?.name,
      'zoneDepart': zoneDepart,
      'zoneAriver': zoneArriver,
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
      'role: ${role.name}, statut: ${statut.name}, identifiant: $identifiant, '
      'lat: $latitude, lng: $longitude, sousZone: ${sousZone?.name}, zone: ${zone?.name}, '
      'typeVehicule: ${typeVehicule?.name})';

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
      orElse: () => SousZone.TUNIS,
    );
  }

  static TypeVehicule? _typeVehiculeFromString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().toUpperCase();
    return TypeVehicule.values.firstWhere(
      (tv) => tv.name.toUpperCase() == s,
      orElse: () => TypeVehicule.DEUX_ROUES_MOTORISES,
    );
  }

  static EtatIncident _etatIncidentFromString(dynamic v) {
    final s = (v ?? '').toString().toUpperCase();
    switch (s) {
      case 'PANNE':
        return EtatIncident.PANNE;
      case 'ACCIDENT':
        return EtatIncident.ACCIDENT;
      case 'RIEN':
      default:
        return EtatIncident.RIEN;
    }
  }

}

// ---------------- ENUMS ----------------

enum Role { client, transporteur, admin }
enum Statut { actif, inactif, banni }
enum EtatIncident { RIEN, PANNE, ACCIDENT }

// --- Enum pour les grandes zones (régions principales) ---
enum Zone {
  GRAND_TUNIS,
  NORD_EST,
  NORD_OUEST,
  CENTRE,
  CENTRE_OUEST,
  SAHEL,
  SFAX,
  SUD_EST,
  SUD_OUEST,
}
// --- Enum pour les sous-zones (zones détaillées pour scooters) ---
enum SousZone {
  // Grand Tunis
  TUNIS,
  ARIANA,
  BEN_AROUS,
  MANOUBA,

  // Nord Est
  BIZERTE,
  NABEUL,

  // Nord Ouest
  BEJA,
  JENDOUBA,
  KEF,
  SILIANA,

  // Centre
  ZAGHOUAN,
  KAIROUAN,

  // Centre Ouest
  KASSERINE,
  SIDI_BOUZID,

  // Sahel
  SOUSSE,
  MONASTIR,
  MAHDIA,

  // Sfax
  SFAX,

  // Sud Est
  GABES,
  MEDENINE,
  TATAOUINE,

  // Sud Ouest
  GAFSA,
  TOZEUR,
  KEBILI,
}

enum TypeVehicule {
  DEUX_ROUES_MOTORISES,
  VEHICULE_PARTICULIER,
  VEHICULE_UTILITAIRE_LEGER,
  FOURGON_MINIBUS,
  GROS_UTILITAIRE,
}
