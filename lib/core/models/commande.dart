// lib/core/models/commande.dart
import 'dart:convert';

/// Modèle aligné 1:1 avec le backend Java `Commande`.
/// ⚠️ AUCUN champ en plus.
/// Champs backend couverts :
/// id, localisationDepart, destination,
/// dateDebut, dateFin, dateDemande,
/// statut, prix, modePaiement, instructions,
/// telDepart, telArrivee,
/// clientId, transporteurId, majLe, idAmie,
/// latitudeDepart, longitudeDepart, latitudeDestination, longitudeDestination, distanceKm,
/// sousZoneDepart, sousZoneArrivee,
/// zonePrincipaleDepart, zonePrincipaleArrivee.
class Commande {
  // Identité
  final String id;

  // Relations (IDs simples)
  final String? clientId;
  final String? transporteurId; // backend: transporteurId (alias id_transporteur / transporteur_id)
  final String? idAmie;

  // Localisation & géo
  final String? localisationDepart;
  final String? destination;
  final double? latitudeDepart;
  final double? longitudeDepart;
  final double? latitudeDestination;
  final double? longitudeDestination;
  final double? distanceKm;

  // Métier
  final String? statut;            // enum côté Java -> String ici
  final double? prix;              // BigDecimal Java -> double
  final String? modePaiement;      // enum Java (EN_LIGNE, DEPART, ARRIVEE) -> String
  final String? instructions;
  final String? telDepart;
  final String? telArrivee;

  // Dates métier (LocalDateTime côté Java)
  final DateTime? dateDemande;     // @CreatedDate
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? majLe;           // @LastModifiedDate

  // Zones (enums Java -> String ici)
  final String? sousZoneDepart;
  final String? sousZoneArrivee;
  final String? zonePrincipaleDepart;
  final String? zonePrincipaleArrivee;

  const Commande({
    required this.id,
    this.clientId,
    this.transporteurId,
    this.idAmie,
    this.localisationDepart,
    this.destination,
    this.latitudeDepart,
    this.longitudeDepart,
    this.latitudeDestination,
    this.longitudeDestination,
    this.distanceKm,
    this.statut,
    this.prix,
    this.modePaiement,
    this.instructions,
    this.telDepart,
    this.telArrivee,
    this.dateDemande,
    this.dateDebut,
    this.dateFin,
    this.majLe,
    this.sousZoneDepart,
    this.sousZoneArrivee,
    this.zonePrincipaleDepart,
    this.zonePrincipaleArrivee,
  });

  // -------- Helpers de parsing sûrs --------
  static double? _toDouble(dynamic v) {
    if (v == null || (v is String && v.trim().isEmpty)) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null || (v is String && v.trim().isEmpty)) return null;
    return DateTime.tryParse(v.toString());
  }

  static String? _toStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  // -------- Parsing tolérant (alias snake/camel) --------
  factory Commande.fromJson(Map<String, dynamic> raw) {
    String _pickId(Map<String, dynamic> m) =>
        (m['id'] ?? m['_id'] ?? '').toString();

    T? _pick<T>(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k] as T?;
      }
      return null;
    }

    return Commande(
      id: _pickId(raw),

      // Relations
      clientId: _toStringOrNull(_pick(raw, ['clientId', 'client_id'])),
      transporteurId: _toStringOrNull(
        _pick(raw, ['transporteurId', 'transporteur_id', 'id_transporteur']),
      ),
      idAmie: _toStringOrNull(_pick(raw, ['idAmie', 'id_amie'])),

      // Localisation & géo
      localisationDepart: _toStringOrNull(
        _pick(raw, ['localisationDepart', 'localisation_depart']),
      ),
      destination: _toStringOrNull(_pick(raw, ['destination'])),
      latitudeDepart: _toDouble(_pick(raw, ['latitudeDepart', 'latitude_depart'])),
      longitudeDepart: _toDouble(_pick(raw, ['longitudeDepart', 'longitude_depart'])),
      latitudeDestination:
          _toDouble(_pick(raw, ['latitudeDestination', 'latitude_destination'])),
      longitudeDestination:
          _toDouble(_pick(raw, ['longitudeDestination', 'longitude_destination'])),
      distanceKm: _toDouble(_pick(raw, ['distanceKm', 'distance_km'])),

      // Métier
      statut: _toStringOrNull(_pick(raw, ['statut'])),
      prix: _toDouble(_pick(raw, ['prix'])),
      modePaiement:
          _toStringOrNull(_pick(raw, ['modePaiement', 'mode_paiement'])),
      instructions: _toStringOrNull(_pick(raw, ['instructions'])),
      telDepart: _toStringOrNull(_pick(raw, ['telDepart', 'tel_depart'])),
      telArrivee: _toStringOrNull(_pick(raw, ['telArrivee', 'tel_arrivee'])),

      // Dates
      dateDemande: _toDate(_pick(raw, ['dateDemande', 'date_demande'])),
      dateDebut: _toDate(_pick(raw, ['dateDebut', 'date_debut'])),
      dateFin: _toDate(_pick(raw, ['dateFin', 'date_fin'])),
      majLe: _toDate(_pick(raw, ['majLe'])),

      // Zones
      sousZoneDepart:
          _toStringOrNull(_pick(raw, ['sousZoneDepart', 'sous_zone_depart'])),
      sousZoneArrivee:
          _toStringOrNull(_pick(raw, ['sousZoneArrivee', 'sous_zone_arrivee'])),
      zonePrincipaleDepart: _toStringOrNull(
        _pick(raw, ['zonePrincipaleDepart', 'zone_principale_depart']),
      ),
      zonePrincipaleArrivee: _toStringOrNull(
        _pick(raw, ['zonePrincipaleArrivee', 'zone_principale_arrivee']),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        // On renvoie en camelCase (adaptable si ton API préfère snake_case).
        'id': id,

        // Relations
        'clientId': clientId,
        'transporteurId': transporteurId,
        'idAmie': idAmie,

        // Localisation & géo
        'localisationDepart': localisationDepart,
        'destination': destination,
        'latitudeDepart': latitudeDepart,
        'longitudeDepart': longitudeDepart,
        'latitudeDestination': latitudeDestination,
        'longitudeDestination': longitudeDestination,
        'distanceKm': distanceKm,

        // Métier
        'statut': statut,
        'prix': prix,
        'modePaiement': modePaiement,
        'instructions': instructions,
        'telDepart': telDepart,
        'telArrivee': telArrivee,

        // Dates
        'dateDemande': dateDemande?.toIso8601String(),
        'dateDebut': dateDebut?.toIso8601String(),
        'dateFin': dateFin?.toIso8601String(),
        'majLe': majLe?.toIso8601String(),

        // Zones
        'sousZoneDepart': sousZoneDepart,
        'sousZoneArrivee': sousZoneArrivee,
        'zonePrincipaleDepart': zonePrincipaleDepart,
        'zonePrincipaleArrivee': zonePrincipaleArrivee,
      };

  static Commande fromJsonString(String jsonStr) =>
      Commande.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  Commande copyWith({
    String? id,
    String? clientId,
    String? transporteurId,
    String? idAmie,
    String? localisationDepart,
    String? destination,
    double? latitudeDepart,
    double? longitudeDepart,
    double? latitudeDestination,
    double? longitudeDestination,
    double? distanceKm,
    String? statut,
    double? prix,
    String? modePaiement,
    String? instructions,
    String? telDepart,
    String? telArrivee,
    DateTime? dateDemande,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? majLe,
    String? sousZoneDepart,
    String? sousZoneArrivee,
    String? zonePrincipaleDepart,
    String? zonePrincipaleArrivee,
  }) {
    return Commande(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      transporteurId: transporteurId ?? this.transporteurId,
      idAmie: idAmie ?? this.idAmie,
      localisationDepart: localisationDepart ?? this.localisationDepart,
      destination: destination ?? this.destination,
      latitudeDepart: latitudeDepart ?? this.latitudeDepart,
      longitudeDepart: longitudeDepart ?? this.longitudeDepart,
      latitudeDestination: latitudeDestination ?? this.latitudeDestination,
      longitudeDestination: longitudeDestination ?? this.longitudeDestination,
      distanceKm: distanceKm ?? this.distanceKm,
      statut: statut ?? this.statut,
      prix: prix ?? this.prix,
      modePaiement: modePaiement ?? this.modePaiement,
      instructions: instructions ?? this.instructions,
      telDepart: telDepart ?? this.telDepart,
      telArrivee: telArrivee ?? this.telArrivee,
      dateDemande: dateDemande ?? this.dateDemande,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      majLe: majLe ?? this.majLe,
      sousZoneDepart: sousZoneDepart ?? this.sousZoneDepart,
      sousZoneArrivee: sousZoneArrivee ?? this.sousZoneArrivee,
      zonePrincipaleDepart:
          zonePrincipaleDepart ?? this.zonePrincipaleDepart,
      zonePrincipaleArrivee:
          zonePrincipaleArrivee ?? this.zonePrincipaleArrivee,
    );
  }
}
