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
  final String?
  transporteurId; // backend: transporteurId (alias id_transporteur / transporteur_id)
  final String? transporteurSecoursId;
  final String? idAmie;
  final String? partenaireId;
  final String? externalBusinessId;
  final String? partenaireNom;
  final String? partenaireLogoUrl;
  final String? externalOrderId;
  final String? nomDepart;
  final String? nomArrivee;

  // Localisation & géo
  final String? localisationDepart;
  final String? destination;
  final double? latitudeDepart;
  final double? longitudeDepart;
  final double? latitudeDestination;
  final double? longitudeDestination;
  final double? distanceKm;

  // Métier
  final String? statut; // enum côté Java -> String ici
  final double? prix; // BigDecimal Java -> double
  final double? prixLivreur;
  final double? prixSociete;
  final double? prixProduitsPartenaire;
  final double? prixLivraison;
  final double? prixTotalClient;
  final String? sourceCommande;
  final String? encaisseurInitial;
  final String? statutReglement;
  final String? statutEncaissementSociete;
  final String? modePaiement; // enum Java (EN_LIGNE, DEPART, ARRIVEE) -> String
  final String? instructions;
  final String? telDepart;
  final String? telArrivee;

  // Dates métier (LocalDateTime côté Java)
  final DateTime? dateDemande; // @CreatedDate
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? dateConfirmer;
  final DateTime? majLe; // @LastModifiedDate

  // Zones (enums Java -> String ici)
  final String? sousZoneDepart;
  final String? sousZoneArrivee;
  final String? zonePrincipaleDepart;
  final String? zonePrincipaleArrivee;

  final bool? qrCodeDepartScanne;
  final DateTime? dateScanDepart;
  final bool? relaisTransporteurEffectue;

  final bool? qrCodeReceptionScanne;
  final DateTime? dateScanReception;

  const Commande({
    required this.id,
    this.clientId,
    this.transporteurId,
    this.transporteurSecoursId,
    this.idAmie,
    this.partenaireId,
    this.externalBusinessId,
    this.partenaireNom,
    this.partenaireLogoUrl,
    this.externalOrderId,
    this.nomDepart,
    this.nomArrivee,
    this.localisationDepart,
    this.destination,
    this.latitudeDepart,
    this.longitudeDepart,
    this.latitudeDestination,
    this.longitudeDestination,
    this.distanceKm,
    this.statut,
    this.prix,
    this.prixLivreur,
    this.prixSociete,
    this.prixProduitsPartenaire,
    this.prixLivraison,
    this.prixTotalClient,
    this.sourceCommande,
    this.encaisseurInitial,
    this.statutReglement,
    this.statutEncaissementSociete,
    this.modePaiement,
    this.instructions,
    this.telDepart,
    this.telArrivee,
    this.dateDemande,
    this.dateDebut,
    this.dateFin,
    this.dateConfirmer,
    this.majLe,
    this.sousZoneDepart,
    this.sousZoneArrivee,
    this.zonePrincipaleDepart,
    this.zonePrincipaleArrivee,
    this.qrCodeDepartScanne,
    this.dateScanDepart,
    this.relaisTransporteurEffectue,
    this.qrCodeReceptionScanne,
    this.dateScanReception,
  });

  bool get isB2c => sourceCommande?.trim().toUpperCase() == 'B2C';

  String? get partenaireDisplayName {
    for (final value in [partenaireNom, nomDepart, externalBusinessId]) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) return normalized;
    }
    return null;
  }

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

    String? _pickTransporteurSecoursId(Map<String, dynamic> m) {
      final direct = _toStringOrNull(
        _pick(m, [
          'transporteurSecoursId',
          'transporteur_secours_id',
          'idTransporteurSecours',
          'id_transporteur_secours',
        ]),
      );
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }
      final nested = m['transporteurSecours'] ?? m['transporteur_secours'];
      if (nested is Map) {
        return _toStringOrNull(nested['id'] ?? nested['_id']);
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
      transporteurSecoursId: _pickTransporteurSecoursId(raw),
      idAmie: _toStringOrNull(_pick(raw, ['idAmie', 'id_amie'])),
      partenaireId: _toStringOrNull(
        _pick(raw, ['partenaireId', 'partenaire_id']),
      ),
      externalBusinessId: _toStringOrNull(
        _pick(raw, ['externalBusinessId', 'external_business_id']),
      ),
      partenaireNom: _toStringOrNull(
        _pick(raw, ['partenaireNom', 'partenaire_nom']),
      ),
      partenaireLogoUrl: _toStringOrNull(
        _pick(raw, ['partenaireLogoUrl', 'partenaire_logo_url']),
      ),
      externalOrderId: _toStringOrNull(
        _pick(raw, ['externalOrderId', 'external_order_id']),
      ),
      nomDepart: _toStringOrNull(_pick(raw, ['nomDepart', 'nom_depart'])),
      nomArrivee: _toStringOrNull(_pick(raw, ['nomArrivee', 'nom_arrivee'])),

      // Localisation & géo
      localisationDepart: _toStringOrNull(
        _pick(raw, ['localisationDepart', 'localisation_depart']),
      ),
      destination: _toStringOrNull(_pick(raw, ['destination'])),
      latitudeDepart: _toDouble(
        _pick(raw, ['latitudeDepart', 'latitude_depart']),
      ),
      longitudeDepart: _toDouble(
        _pick(raw, ['longitudeDepart', 'longitude_depart']),
      ),
      latitudeDestination: _toDouble(
        _pick(raw, ['latitudeDestination', 'latitude_destination']),
      ),
      longitudeDestination: _toDouble(
        _pick(raw, ['longitudeDestination', 'longitude_destination']),
      ),
      distanceKm: _toDouble(_pick(raw, ['distanceKm', 'distance_km'])),

      // Métier
      statut: _toStringOrNull(_pick(raw, ['statut'])),
      prix: _toDouble(_pick(raw, ['prix'])),
      prixLivreur: _toDouble(_pick(raw, ['prixLivreur', 'prix_livreur'])),
      prixSociete: _toDouble(_pick(raw, ['prixSociete', 'prix_societe'])),
      prixProduitsPartenaire: _toDouble(
        _pick(raw, ['prixProduitsPartenaire', 'prix_produits_partenaire']),
      ),
      prixLivraison: _toDouble(_pick(raw, ['prixLivraison', 'prix_livraison'])),
      prixTotalClient: _toDouble(
        _pick(raw, ['prixTotalClient', 'prix_total_client']),
      ),
      sourceCommande: _toStringOrNull(
        _pick(raw, ['sourceCommande', 'source_commande']),
      ),
      encaisseurInitial: _toStringOrNull(
        _pick(raw, ['encaisseurInitial', 'encaisseur_initial']),
      ),
      statutReglement: _toStringOrNull(
        _pick(raw, ['statutReglement', 'statut_reglement']),
      ),
      statutEncaissementSociete: _toStringOrNull(
        _pick(raw, [
          'statutEncaissementSociete',
          'statut_encaissement_societe',
        ]),
      ),
      modePaiement: _toStringOrNull(
        _pick(raw, ['modePaiement', 'mode_paiement']),
      ),
      instructions: _toStringOrNull(_pick(raw, ['instructions'])),
      telDepart: _toStringOrNull(_pick(raw, ['telDepart', 'tel_depart'])),
      telArrivee: _toStringOrNull(_pick(raw, ['telArrivee', 'tel_arrivee'])),

      // Dates
      dateDemande: _toDate(_pick(raw, ['dateDemande', 'date_demande'])),
      dateDebut: _toDate(_pick(raw, ['dateDebut', 'date_debut'])),
      dateFin: _toDate(_pick(raw, ['dateFin', 'date_fin'])),
      dateConfirmer: _toDate(_pick(raw, ['dateConfirmer', 'date_confirmer'])),
      majLe: _toDate(_pick(raw, ['majLe'])),

      // Zones
      sousZoneDepart: _toStringOrNull(
        _pick(raw, ['sousZoneDepart', 'sous_zone_depart']),
      ),
      sousZoneArrivee: _toStringOrNull(
        _pick(raw, ['sousZoneArrivee', 'sous_zone_arrivee']),
      ),
      zonePrincipaleDepart: _toStringOrNull(
        _pick(raw, ['zonePrincipaleDepart', 'zone_principale_depart']),
      ),
      zonePrincipaleArrivee: _toStringOrNull(
        _pick(raw, ['zonePrincipaleArrivee', 'zone_principale_arrivee']),
      ),
      qrCodeDepartScanne:
          _pick(raw, ['qrCodeDepartScanne', 'qr_code_depart_scanne']) as bool?,
      dateScanDepart: _toDate(
        _pick(raw, ['dateScanDepart', 'date_scan_depart']),
      ),
      relaisTransporteurEffectue:
          _pick(raw, [
                'relaisTransporteurEffectue',
                'relais_transporteur_effectue',
              ])
              as bool?,
      qrCodeReceptionScanne:
          _pick(raw, ['qrCodeReceptionScanne', 'qr_code_reception_scanne'])
              as bool?,
      dateScanReception: _toDate(
        _pick(raw, ['dateScanReception', 'date_scan_reception']),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    // On renvoie en camelCase (adaptable si ton API préfère snake_case).
    'id': id,

    // Relations
    'clientId': clientId,
    'transporteurId': transporteurId,
    'transporteurSecoursId': transporteurSecoursId,
    'idAmie': idAmie,
    'partenaireId': partenaireId,
    'externalBusinessId': externalBusinessId,
    'partenaireNom': partenaireNom,
    'partenaireLogoUrl': partenaireLogoUrl,
    'externalOrderId': externalOrderId,
    'nomDepart': nomDepart,
    'nomArrivee': nomArrivee,

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
    'prixLivreur': prixLivreur,
    'prixSociete': prixSociete,
    'prixProduitsPartenaire': prixProduitsPartenaire,
    'prixLivraison': prixLivraison,
    'prixTotalClient': prixTotalClient,
    'sourceCommande': sourceCommande,
    'encaisseurInitial': encaisseurInitial,
    'statutReglement': statutReglement,
    'statutEncaissementSociete': statutEncaissementSociete,
    'modePaiement': modePaiement,
    'instructions': instructions,
    'telDepart': telDepart,
    'telArrivee': telArrivee,

    // Dates
    'dateDemande': dateDemande?.toIso8601String(),
    'dateDebut': dateDebut?.toIso8601String(),
    'dateFin': dateFin?.toIso8601String(),
    'dateConfirmer': dateConfirmer?.toIso8601String(),
    'majLe': majLe?.toIso8601String(),

    // Zones
    'sousZoneDepart': sousZoneDepart,
    'sousZoneArrivee': sousZoneArrivee,
    'zonePrincipaleDepart': zonePrincipaleDepart,
    'zonePrincipaleArrivee': zonePrincipaleArrivee,
    'qrCodeDepartScanne': qrCodeDepartScanne,
    'dateScanDepart': dateScanDepart?.toIso8601String(),
    'relaisTransporteurEffectue': relaisTransporteurEffectue,
    'qrCodeReceptionScanne': qrCodeReceptionScanne,
    'dateScanReception': dateScanReception?.toIso8601String(),
  };

  static Commande fromJsonString(String jsonStr) =>
      Commande.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  Commande copyWith({
    String? id,
    String? clientId,
    String? transporteurId,
    String? transporteurSecoursId,
    String? idAmie,
    String? partenaireId,
    String? externalBusinessId,
    String? partenaireNom,
    String? partenaireLogoUrl,
    String? externalOrderId,
    String? nomDepart,
    String? nomArrivee,
    String? localisationDepart,
    String? destination,
    double? latitudeDepart,
    double? longitudeDepart,
    double? latitudeDestination,
    double? longitudeDestination,
    double? distanceKm,
    String? statut,
    double? prix,
    double? prixLivreur,
    double? prixSociete,
    double? prixProduitsPartenaire,
    double? prixLivraison,
    double? prixTotalClient,
    String? sourceCommande,
    String? encaisseurInitial,
    String? statutReglement,
    String? statutEncaissementSociete,
    String? modePaiement,
    String? instructions,
    String? telDepart,
    String? telArrivee,
    DateTime? dateDemande,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? dateConfirmer,
    DateTime? majLe,
    String? sousZoneDepart,
    String? sousZoneArrivee,
    String? zonePrincipaleDepart,
    String? zonePrincipaleArrivee,
    bool? qrCodeDepartScanne,
    DateTime? dateScanDepart,
    bool? relaisTransporteurEffectue,
    bool? qrCodeReceptionScanne,
    DateTime? dateScanReception,
  }) {
    return Commande(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      transporteurId: transporteurId ?? this.transporteurId,
      transporteurSecoursId:
          transporteurSecoursId ?? this.transporteurSecoursId,
      idAmie: idAmie ?? this.idAmie,
      partenaireId: partenaireId ?? this.partenaireId,
      externalBusinessId: externalBusinessId ?? this.externalBusinessId,
      partenaireNom: partenaireNom ?? this.partenaireNom,
      partenaireLogoUrl: partenaireLogoUrl ?? this.partenaireLogoUrl,
      externalOrderId: externalOrderId ?? this.externalOrderId,
      nomDepart: nomDepart ?? this.nomDepart,
      nomArrivee: nomArrivee ?? this.nomArrivee,
      localisationDepart: localisationDepart ?? this.localisationDepart,
      destination: destination ?? this.destination,
      latitudeDepart: latitudeDepart ?? this.latitudeDepart,
      longitudeDepart: longitudeDepart ?? this.longitudeDepart,
      latitudeDestination: latitudeDestination ?? this.latitudeDestination,
      longitudeDestination: longitudeDestination ?? this.longitudeDestination,
      distanceKm: distanceKm ?? this.distanceKm,
      statut: statut ?? this.statut,
      prix: prix ?? this.prix,
      prixLivreur: prixLivreur ?? this.prixLivreur,
      prixSociete: prixSociete ?? this.prixSociete,
      prixProduitsPartenaire:
          prixProduitsPartenaire ?? this.prixProduitsPartenaire,
      prixLivraison: prixLivraison ?? this.prixLivraison,
      prixTotalClient: prixTotalClient ?? this.prixTotalClient,
      sourceCommande: sourceCommande ?? this.sourceCommande,
      encaisseurInitial: encaisseurInitial ?? this.encaisseurInitial,
      statutReglement: statutReglement ?? this.statutReglement,
      statutEncaissementSociete:
          statutEncaissementSociete ?? this.statutEncaissementSociete,
      modePaiement: modePaiement ?? this.modePaiement,
      instructions: instructions ?? this.instructions,
      telDepart: telDepart ?? this.telDepart,
      telArrivee: telArrivee ?? this.telArrivee,
      dateDemande: dateDemande ?? this.dateDemande,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      dateConfirmer: dateConfirmer ?? this.dateConfirmer,
      majLe: majLe ?? this.majLe,
      sousZoneDepart: sousZoneDepart ?? this.sousZoneDepart,
      sousZoneArrivee: sousZoneArrivee ?? this.sousZoneArrivee,
      zonePrincipaleDepart: zonePrincipaleDepart ?? this.zonePrincipaleDepart,
      zonePrincipaleArrivee:
          zonePrincipaleArrivee ?? this.zonePrincipaleArrivee,
      qrCodeDepartScanne: qrCodeDepartScanne ?? this.qrCodeDepartScanne,
      dateScanDepart: dateScanDepart ?? this.dateScanDepart,
      relaisTransporteurEffectue:
          relaisTransporteurEffectue ?? this.relaisTransporteurEffectue,
      qrCodeReceptionScanne:
          qrCodeReceptionScanne ?? this.qrCodeReceptionScanne,
      dateScanReception: dateScanReception ?? this.dateScanReception,
    );
  }
}
