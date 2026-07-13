// lib/features/commande/dto/commande_dto.dart
import 'dart:convert';

class CommandeDto {
  final String? clientId;
  final String? transporteurId; // alias back: id_transporteur / transporteur_id
  final String? idAmie;

  final String? localisationDepart;
  final String? destination;

  final double? latitudeDepart;
  final double? longitudeDepart;
  final double? latitudeDestination;
  final double? longitudeDestination;
  final double? distanceKm;

  final String? statut; // enum Java -> String
  final double? prix; // BigDecimal -> double

  final String? modePaiement; // enum Java: EN_LIGNE, DEPART, ARRIVEE
  final String? instructions;
  final String? telDepart;
  final String? telArrivee;

  final DateTime? dateDemande;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? majLe;

  final String? sousZoneDepart;
  final String? sousZoneArrivee;
  final String? zonePrincipaleDepart;
  final String? zonePrincipaleArrivee;

  const CommandeDto({
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

  factory CommandeDto.fromJson(Map<String, dynamic> raw) {
    T? pick<T>(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k] as T?;
      }
      return null;
    }

    return CommandeDto(
      clientId: _toStringOrNull(pick(raw, ['clientId', 'client_id'])),
      transporteurId: _toStringOrNull(
        pick(raw, ['transporteurId', 'transporteur_id', 'id_transporteur']),
      ),
      idAmie: _toStringOrNull(pick(raw, ['idAmie', 'id_amie'])),

      localisationDepart: _toStringOrNull(
        pick(raw, ['localisationDepart', 'localisation_depart']),
      ),
      destination: _toStringOrNull(pick(raw, ['destination'])),

      latitudeDepart: _toDouble(
        pick(raw, ['latitudeDepart', 'latitude_depart']),
      ),
      longitudeDepart: _toDouble(
        pick(raw, ['longitudeDepart', 'longitude_depart']),
      ),
      latitudeDestination: _toDouble(
        pick(raw, ['latitudeDestination', 'latitude_destination']),
      ),
      longitudeDestination: _toDouble(
        pick(raw, ['longitudeDestination', 'longitude_destination']),
      ),
      distanceKm: _toDouble(pick(raw, ['distanceKm', 'distance_km'])),

      statut: _toStringOrNull(pick(raw, ['statut'])),
      prix: _toDouble(pick(raw, ['prix'])),

      modePaiement: _toStringOrNull(
        pick(raw, ['modePaiement', 'mode_paiement']),
      ),
      instructions: _toStringOrNull(pick(raw, ['instructions'])),
      telDepart: _toStringOrNull(pick(raw, ['telDepart', 'tel_depart'])),
      telArrivee: _toStringOrNull(pick(raw, ['telArrivee', 'tel_arrivee'])),

      dateDemande: _toDate(pick(raw, ['dateDemande', 'date_demande'])),
      dateDebut: _toDate(pick(raw, ['dateDebut', 'date_debut'])),
      dateFin: _toDate(pick(raw, ['dateFin', 'date_fin'])),
      majLe: _toDate(pick(raw, ['majLe'])),

      sousZoneDepart: _toStringOrNull(
        pick(raw, ['sousZoneDepart', 'sous_zone_depart']),
      ),
      sousZoneArrivee: _toStringOrNull(
        pick(raw, ['sousZoneArrivee', 'sous_zone_arrivee']),
      ),
      zonePrincipaleDepart: _toStringOrNull(
        pick(raw, ['zonePrincipaleDepart', 'zone_principale_depart']),
      ),
      zonePrincipaleArrivee: _toStringOrNull(
        pick(raw, ['zonePrincipaleArrivee', 'zone_principale_arrivee']),
      ),
    );
  }

  Map<String, dynamic> toJson({bool snakeCase = false}) {
    if (!snakeCase) {
      // camelCase (par défaut)
      return {
        'clientId': clientId,
        'transporteurId': transporteurId,
        'idAmie': idAmie,
        'localisationDepart': localisationDepart,
        'destination': destination,
        'latitudeDepart': latitudeDepart,
        'longitudeDepart': longitudeDepart,
        'latitudeDestination': latitudeDestination,
        'longitudeDestination': longitudeDestination,
        'distanceKm': distanceKm,
        'statut': statut,
        'prix': prix,
        'modePaiement': modePaiement,
        'instructions': instructions,
        'telDepart': telDepart,
        'telArrivee': telArrivee,
        'dateDemande': dateDemande?.toIso8601String(),
        'dateDebut': dateDebut?.toIso8601String(),
        'dateFin': dateFin?.toIso8601String(),
        'majLe': majLe?.toIso8601String(),
        'sousZoneDepart': sousZoneDepart,
        'sousZoneArrivee': sousZoneArrivee,
        'zonePrincipaleDepart': zonePrincipaleDepart,
        'zonePrincipaleArrivee': zonePrincipaleArrivee,
      };
    } else {
      // snake_case (si ton API l'exige)
      return {
        'client_id': clientId,
        'transporteur_id': transporteurId,
        'id_amie': idAmie,
        'localisation_depart': localisationDepart,
        'destination': destination,
        'latitude_depart': latitudeDepart,
        'longitude_depart': longitudeDepart,
        'latitude_destination': latitudeDestination,
        'longitude_destination': longitudeDestination,
        'distance_km': distanceKm,
        'statut': statut,
        'prix': prix,
        'mode_paiement': modePaiement,
        'instructions': instructions,
        'tel_depart': telDepart,
        'tel_arrivee': telArrivee,
        'date_demande': dateDemande?.toIso8601String(),
        'date_debut': dateDebut?.toIso8601String(),
        'date_fin': dateFin?.toIso8601String(),
        'majLe': majLe?.toIso8601String(), // le back use "majLe"
        'sous_zone_depart': sousZoneDepart,
        'sous_zone_arrivee': sousZoneArrivee,
        'zone_principale_depart': zonePrincipaleDepart,
        'zone_principale_arrivee': zonePrincipaleArrivee,
      };
    }
  }

  static CommandeDto fromJsonString(String jsonStr) =>
      CommandeDto.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  String toJsonString({bool snakeCase = false}) =>
      json.encode(toJson(snakeCase: snakeCase));

  CommandeDto copyWith({
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
    return CommandeDto(
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
      zonePrincipaleDepart: zonePrincipaleDepart ?? this.zonePrincipaleDepart,
      zonePrincipaleArrivee:
          zonePrincipaleArrivee ?? this.zonePrincipaleArrivee,
    );
  }
}
