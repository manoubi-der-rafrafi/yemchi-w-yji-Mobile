// lib/features/commande/data/commande_service.dart
import 'dart:convert';

import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/commande/dto/commande_dto.dart';
import 'package:yemchi_wyji/features/commande/dto/commande_produits_response.dart';
import 'package:yemchi_wyji/features/commande/dto/commande_transporteur_principal_response.dart';
import 'package:yemchi_wyji/features/commande/dto/transporteur_panne_commandes_response.dart';
import 'package:yemchi_wyji/features/commande/dto/transporteur_secours_commandes_response.dart';
class CommandeService {
  final Api api;
  CommandeService(this.api);

  /// NB: le backend est mappé sur "/api/commandes" côté Spring.
  /// Ton Api() devrait déjà préfixer par "/api".
  static const String _base = '/commandes';

  // ------------------ LISTE ------------------
  /// GET /commandes
  /// Supporte soit une liste simple, soit une page Spring Data (clé "content")
  Future<List<Commande>> getAll() async {
    final res = await api.get(_base);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET $_base -> ${res.statusCode}: ${res.body}');
    }

    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded.map<Commande>((e) => Commande.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (decoded is Map && decoded['content'] is List) {
      return (decoded['content'] as List)
          .map<Commande>((e) => Commande.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const <Commande>[];
  }

  // ------------------ DÉTAIL ------------------
  /// GET /commandes/{id}
  Future<Commande> getById(String id) async {
    final res = await api.get('$_base/$id');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET $_base/$id -> ${res.statusCode}: ${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return Commande.fromJson(map);
  }

  // ------------------ CRÉATION ------------------
  /// POST /commandes
  /// Utilise CommandeDto.toJson() (camelCase par défaut)
  Future<Commande> create(CommandeDto dto) async {
    final res = await api.post(_base, body: json.encode(dto.toJson()));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('POST $_base -> ${res.statusCode}: ${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return Commande.fromJson(map);
  }

  // ------------------ MISE À JOUR ------------------
  /// PUT /commandes/{id}
  /// Utilise CommandeDto.toJson() (camelCase par défaut)
  Future<Commande> update(String id, CommandeDto dto) async {
    final res = await api.put('$_base/$id', body: json.encode(dto.toJson()));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PUT $_base/$id -> ${res.statusCode}: ${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return Commande.fromJson(map);
  }

  // ------------------ SPÉCIFIQUES BACKEND ------------------

  /// PUT /commandes/{id}/confirmer
  Future<Commande> confirmerCommande(String id) async {
    final res = await api.put('$_base/$id/confirmer', body: json.encode({}));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PUT $_base/$id/confirmer -> ${res.statusCode}: ${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return Commande.fromJson(map);
  }

  /// GET /commandes/{id}/transporteurs-min-commandes
  /// Retourne la liste des ids transporteurs.
  Future<List<String>> getTransporteursMinCommandes(String id) async {
    final res = await api.get('$_base/$id/transporteurs-min-commandes');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/$id/transporteurs-min-commandes -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded.map<String>((e) => e.toString()).toList();
    }
    return const <String>[];
  }

  /// PUT /commandes/{id}/scan-depart
  Future<Commande> marquerDepartScanne(String id) async {
    final res = await api.put('$_base/$id/scan-depart', body: json.encode({}));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PUT $_base/$id/scan-depart -> ${res.statusCode}: ${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return Commande.fromJson(map);
  }

  /// PUT /commandes/{id}/scan-reception
  Future<Commande> marquerReceptionScanne(String id) async {
    final res = await api.put('$_base/$id/scan-reception', body: json.encode({}));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PUT $_base/$id/scan-reception -> ${res.statusCode}: ${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return Commande.fromJson(map);
  }

  Future<Commande> marquerRelaisTransporteurEffectue(String id) async {
    final res = await api.put(
      '$_base/$id/relais-transporteur-effectue',
      body: json.encode({}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'PUT $_base/$id/relais-transporteur-effectue -> ${res.statusCode}: ${res.body}',
      );
    }
    final body = res.body.trim();
    if (body.isEmpty || body == 'null') {
      return getById(id);
    }
    final map = json.decode(body) as Map<String, dynamic>;
    return Commande.fromJson(map);
  }

  Future<Utilisateur> reinitialiserEtatIncidentTransporteur(String id) async {
    final res = await api.put(
      '/utilisateur/$id/etat-incident/rien',
      body: json.encode({}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'PUT /utilisateur/$id/etat-incident/rien -> ${res.statusCode}: ${res.body}',
      );
    }
    final body = res.body.trim();
    if (body.isEmpty || body == 'null') {
      throw Exception('Reponse vide lors de la reinitialisation de l etat incident.');
    }
    final map = json.decode(body) as Map<String, dynamic>;
    return Utilisateur.fromJson(map);
  }

  /// GET /commandes/ami/{idAmie}
  Future<List<Commande>> getByIdAmie(String idAmie) async {
    final res = await api.get('$_base/ami/$idAmie');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET $_base/ami/$idAmie -> ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded.map<Commande>((e) => Commande.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/ami/{idAmie}/count
  Future<int> countByIdAmie(String idAmie) async {
    final res = await api.get('$_base/ami/$idAmie/count');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET $_base/ami/$idAmie/count -> ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is num) return decoded.toInt();
    if (decoded is String) return int.tryParse(decoded) ?? 0;
    return 0;
    }

  /// GET /commandes/ami/{idAmie}/count/envoyee
  Future<int> countByIdAmieEnvoyee(String idAmie) async {
    final res = await api.get('$_base/ami/$idAmie/count/envoyee');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET $_base/ami/$idAmie/count/envoyee -> ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is num) return decoded.toInt();
    if (decoded is String) return int.tryParse(decoded) ?? 0;
    return 0;
  }

  /// GET /commandes/zone/{zone}
  /// Retourne toutes les commandes dont zonePrincipaleDepart = zonePrincipaleArrivee = {zone}
  /// Exemple: zone = "GRAND_TUNIS", "NORD_EST", "NORD_OUEST", "CENTRE", "CENTRE_OUEST", "SAHEL", "SFAX", "SUD_EST", "SUD_OUEST"
  Future<List<Commande>> getByZone(String zone) async {
    final res = await api.get('$_base/zone/$zone/confirmees');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET $_base/zone/$zone/confirmees -> ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded.map<Commande>((e) => Commande.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/zone/{zone}/vehicule/{vehicule}
  Future<List<Commande>> getByZoneAndVehicule({
    required String zone,
    required String vehicule,
  }) async {
    final res = await api.get('$_base/zone/$zone/vehicule/$vehicule');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET $_base/zone/$zone/vehicule/$vehicule -> ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded.map<Commande>((e) => Commande.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const <Commande>[];
  }

  /// POST /commandes/sous-zones
  /// Permet de filtrer par listes de sous-zones depart / arrivee via le body:
  /// { "sousZonesDepart": ["..."], "sousZonesArrivee": ["..."] }
  Future<List<Commande>> getBySousZones({
    List<String>? sousZonesDepart,
    List<String>? sousZonesArrivee,
  }) async {
    final payload = json.encode({
      'sousZonesDepart': sousZonesDepart ?? const <String>[],
      'sousZonesArrivee': sousZonesArrivee ?? const <String>[],
    });
    final res = await api.post('$_base/sous-zones', body: payload);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST $_base/sous-zones -> ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded.map<Commande>((e) => Commande.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const <Commande>[];
  }

  /// POST /commandes/sous-zones/vehicule
  /// Body: { "sousZonesDepart": [...], "sousZonesArrivee": [...], "vehicule": ... }
  Future<List<Commande>> getBySousZonesAndVehicule({
    List<String>? sousZonesDepart,
    List<String>? sousZonesArrivee,
    required Object vehicule,
  }) async {
    final payload = json.encode({
      'sousZonesDepart': sousZonesDepart ?? const <String>[],
      'sousZonesArrivee': sousZonesArrivee ?? const <String>[],
      'vehicule': vehicule,
    });
    final res = await api.post('$_base/sous-zones/vehicule', body: payload);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST $_base/sous-zones/vehicule -> ${res.statusCode}: ${res.body}');
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded.map<Commande>((e) => Commande.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const <Commande>[];
  }

  Future<Commande> assignerTransporteur(String idCommande, String idTransporteur) async {
  final res = await api.put('/commandes/$idCommande/assigner/$idTransporteur', body: '{}');
  if (res.statusCode == 400) {
    throw StateError('Commande deja assignee ou invalide.');
  }
  if (res.statusCode == 404) {
    throw ArgumentError('Commande ou transporteur introuvable.');
  }
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('PUT /commandes/$idCommande/assigner/$idTransporteur -> ${res.statusCode}: ${res.body}');
  }
  final body = res.body.trim();
  if (body.isEmpty || body == 'null') {
    return getById(idCommande);
  }
  try {
    final map = json.decode(body) as Map<String, dynamic>;
    return Commande.fromJson(map);
  } catch (_) {
    return getById(idCommande);
  }
}

  Future<Commande> assignerTransporteurSecours(
    String idCommande,
    String idTransporteurSecours,
  ) async {
    try {
      final res = await api.put(
        '$_base/$idCommande/transporteur-secours/$idTransporteurSecours',
        body: '{}',
      );
      final body = res.body.trim();
      if (body.isEmpty || body == 'null') {
        return getById(idCommande);
      }
      final map = json.decode(body) as Map<String, dynamic>;
      return Commande.fromJson(map);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw StateError(
          _userVisibleApiMessage(
            e,
            fallback: 'Acces refuse pour assigner le transporteur secours.',
          ),
        );
      }
      if (e.statusCode == 404) {
        throw ArgumentError(
          _userVisibleApiMessage(
            e,
            fallback: 'Commande ou transporteur secours introuvable.',
          ),
        );
      }
      if (e.statusCode == 400) {
        throw StateError(
          _userVisibleApiMessage(
            e,
            fallback: 'Commande invalide pour un transporteur secours.',
          ),
        );
      }
      throw StateError(
        _userVisibleApiMessage(
          e,
          fallback: 'Erreur serveur lors de l assignation du transporteur secours.',
        ),
      );
    } catch (_) {
      return getById(idCommande);
    }
  }

  String _userVisibleApiMessage(ApiException e, {required String fallback}) {
    final message = e.message.trim();
    if (message.isEmpty) return fallback;
    if (message.startsWith('<!DOCTYPE html') || message.startsWith('<html')) {
      return fallback;
    }
    return message;
  }

  /// PUT /commandes/{id}/appel-client-1
  Future<Commande> marquerAppelClient1(String idCommande) async {
    final res = await api.put('$_base/$idCommande/appel-client-1', body: '{}');
    if (res.statusCode == 400) {
      throw StateError('Commande deja assignee ou invalide.');
    }
    if (res.statusCode == 404) {
      throw ArgumentError('Commande introuvable.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'PUT $_base/$idCommande/appel-client-1 -> ${res.statusCode}: ${res.body}',
      );
    }
    final body = res.body.trim();
    if (body.isEmpty || body == 'null') {
      return getById(idCommande);
    }
    try {
      final map = json.decode(body) as Map<String, dynamic>;
      return Commande.fromJson(map);
    } catch (_) {
      return getById(idCommande);
    }
  }

  /// PUT /commandes/{id}/debut-appel-client-1
  Future<Commande> demarrerAppelClient1(String idCommande) async {
    final res =
        await api.put('$_base/$idCommande/debut-appel-client-1', body: '{}');
    if (res.statusCode == 400) {
      throw StateError('Commande deja assignee ou invalide.');
    }
    if (res.statusCode == 404) {
      throw ArgumentError('Commande introuvable.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'PUT $_base/$idCommande/debut-appel-client-1 -> ${res.statusCode}: ${res.body}',
      );
    }
    final body = res.body.trim();
    if (body.isEmpty || body == 'null') {
      return getById(idCommande);
    }
    try {
      final map = json.decode(body) as Map<String, dynamic>;
      return Commande.fromJson(map);
    } catch (_) {
      return getById(idCommande);
    }
  }

  /// PUT /commandes/{id}/appel-client-2
  Future<Commande> marquerAppelClient2(String idCommande) async {
    final res = await api.put('$_base/$idCommande/appel-client-2', body: '{}');
    if (res.statusCode == 400) {
      throw StateError('Commande deja assignee ou invalide.');
    }
    if (res.statusCode == 404) {
      throw ArgumentError('Commande introuvable.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'PUT $_base/$idCommande/appel-client-2 -> ${res.statusCode}: ${res.body}',
      );
    }
    final body = res.body.trim();
    if (body.isEmpty || body == 'null') {
      return getById(idCommande);
    }
    try {
      final map = json.decode(body) as Map<String, dynamic>;
      return Commande.fromJson(map);
    } catch (_) {
      return getById(idCommande);
    }
  }

  /// PUT /commandes/{id}/non-repondre-client-1
  Future<Commande> marquerNonReponseClient1(String idCommande) async {
    final res =
        await api.put('$_base/$idCommande/non-repondre-client-1', body: '{}');
    if (res.statusCode == 400) {
      throw StateError('Commande deja assignee ou invalide.');
    }
    if (res.statusCode == 404) {
      throw ArgumentError('Commande introuvable.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'PUT $_base/$idCommande/non-repondre-client-1 -> ${res.statusCode}: ${res.body}',
      );
    }
    final body = res.body.trim();
    if (body.isEmpty || body == 'null') {
      return getById(idCommande);
    }
    try {
      final map = json.decode(body) as Map<String, dynamic>;
      return Commande.fromJson(map);
    } catch (_) {
      return getById(idCommande);
    }
  }

  /// PUT /commandes/{id}/non-repondre-client-2
  Future<Commande> marquerNonReponseClient2(String idCommande) async {
    final res =
        await api.put('$_base/$idCommande/non-repondre-client-2', body: '{}');
    if (res.statusCode == 400) {
      throw StateError('Commande deja assignee ou invalide.');
    }
    if (res.statusCode == 404) {
      throw ArgumentError('Commande introuvable.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'PUT $_base/$idCommande/non-repondre-client-2 -> ${res.statusCode}: ${res.body}',
      );
    }
    final body = res.body.trim();
    if (body.isEmpty || body == 'null') {
      return getById(idCommande);
    }
    try {
      final map = json.decode(body) as Map<String, dynamic>;
      return Commande.fromJson(map);
    } catch (_) {
      return getById(idCommande);
    }
  }
  /// GET /commandes/transporteur/{idTransporteur}
  Future<List<Commande>> getCommandesByTransporteur(String idTransporteur) async {
    final res = await api.get('$_base/transporteur/$idTransporteur');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .map<Commande>((item) => Commande.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/transporteur/{idTransporteur}/etat-incident/{etatIncident}
  Future<List<Commande>> getCommandesByTransporteurAndEtatIncident(
    String idTransporteur,
    EtatIncident etatIncident,
  ) async {
    final res = await api.get(
      '$_base/transporteur/$idTransporteur/etat-incident/${etatIncident.name}',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/etat-incident/${etatIncident.name}'
        ' -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .map<Commande>(
            (item) => Commande.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/transporteur/{idTransporteur}/livrees
  Future<List<Commande>> getCommandesLivreesByTransporteur(
    String idTransporteur,
  ) async {
    final res = await api.get('$_base/transporteur/$idTransporteur/livrees');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/livrees -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .map<Commande>((item) => Commande.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/transporteur/{idTransporteur}/non-livrees
  Future<List<Commande>> getCommandesNonLivreesByTransporteur(
    String idTransporteur,
  ) async {
    final res =
        await api.get('$_base/transporteur/$idTransporteur/non-livrees');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/non-livrees -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .map<Commande>((item) => Commande.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/transporteur/{idTransporteur}/en-ligne
  Future<List<Commande>> getCommandesEnLigneByTransporteur(
    String idTransporteur,
  ) async {
    final res = await api.get('$_base/transporteur/$idTransporteur/en-ligne');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/en-ligne -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .map<Commande>((item) => Commande.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/transporteur/{idTransporteur}/hors-ligne
  Future<List<Commande>> getCommandesHorsLigneByTransporteur(
    String idTransporteur,
  ) async {
    final res = await api.get('$_base/transporteur/$idTransporteur/hors-ligne');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/hors-ligne -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .map<Commande>((item) => Commande.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/transporteur/{idTransporteur}/sous-zone/{sousZone}/en-ligne
  Future<List<Commande>> getCommandesEnLigneByTransporteurAndSousZone(
    String idTransporteur,
    String sousZone,
  ) async {
    final res = await api.get(
      '$_base/transporteur/$idTransporteur/sous-zone/$sousZone/en-ligne',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/sous-zone/$sousZone/en-ligne -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .map<Commande>((item) => Commande.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/transporteur/{idTransporteur}/sous-zone/{sousZone}/hors-ligne
  Future<List<Commande>> getCommandesHorsLigneByTransporteurAndSousZone(
    String idTransporteur,
    String sousZone,
  ) async {
    final res = await api.get(
      '$_base/transporteur/$idTransporteur/sous-zone/$sousZone/hors-ligne',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/sous-zone/$sousZone/hors-ligne -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .map<Commande>((item) => Commande.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const <Commande>[];
  }

  /// GET /commandes/transporteur/{idTransporteur}/en-route/produits
  Future<List<CommandeProduitsResponse>>
      getCommandesEnRouteAvecProduitsByTransporteur(
    String idTransporteur,
  ) async {
    final res = await api.get(
      '$_base/transporteur/$idTransporteur/en-route/produits',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/en-route/produits -> ${res.statusCode}: ${res.body}',
      );
    }

    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) => CommandeProduitsResponse.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList();
    }
    return const <CommandeProduitsResponse>[];
  }

  Future<List<CommandeTransporteurPrincipalResponse>>
      getCommandesEnRouteByTransporteurSecours(
    String idTransporteur,
  ) async {
    final res = await api.get(
      '$_base/transporteur-secours/$idTransporteur/en-route',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur-secours/$idTransporteur/en-route'
        ' -> ${res.statusCode}: ${res.body}',
      );
    }

    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) => CommandeTransporteurPrincipalResponse.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList();
    }
    return const <CommandeTransporteurPrincipalResponse>[];
  }

  Future<List<TransporteurPanneCommandesResponse>>
      getTransporteursEnPanneAvecCommandes() async {
    final res = await api.get('/utilisateur/transporteurs/panne/commandes');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET /utilisateur/transporteurs/panne/commandes -> ${res.statusCode}: ${res.body}',
      );
    }

    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) => TransporteurPanneCommandesResponse.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList();
    }
    return const <TransporteurPanneCommandesResponse>[];
  }

  Future<List<TransporteurSecoursCommandesResponse>>
      getTransporteursSecoursAvecCommandes(String idTransporteur) async {
    final res = await api.get('$_base/transporteur/$idTransporteur/secours');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/secours'
        ' -> ${res.statusCode}: ${res.body}',
      );
    }

    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) => TransporteurSecoursCommandesResponse.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList();
    }
    return const <TransporteurSecoursCommandesResponse>[];
  }

  /// GET /commandes/transporteur/{idTransporteur}/total-livree
  Future<double> getSommePrixLivreeByTransporteur(String idTransporteur) async {
    final res = await api.get('$_base/transporteur/$idTransporteur/total-livree');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/total-livree -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    final total = _parseDouble(decoded) ??
        (decoded is Map<String, dynamic>
            ? _parseDouble(decoded['total'] ?? decoded['value'])
            : null);
    if (total != null) return total;
    throw Exception('Format inattendu pour total-livree: ${res.body}');
  }

  /// GET /commandes/transporteur/{idTransporteur}/total-livree-en-ligne
  Future<double> getSommePrixLivreeEnLigneByTransporteur(
    String idTransporteur,
  ) async {
    final res =
        await api.get('$_base/transporteur/$idTransporteur/total-livree-en-ligne');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/total-livree-en-ligne -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    final total = _parseDouble(decoded) ??
        (decoded is Map<String, dynamic>
            ? _parseDouble(decoded['total'] ?? decoded['value'])
            : null);
    if (total != null) return total;
    throw Exception('Format inattendu pour total-livree-en-ligne: ${res.body}');
  }

  /// GET /commandes/transporteur/{idTransporteur}/total-livree-hors-ligne
  Future<double> getSommePrixLivreeHorsLigneByTransporteur(
    String idTransporteur,
  ) async {
    final res = await api
        .get('$_base/transporteur/$idTransporteur/total-livree-hors-ligne');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/total-livree-hors-ligne -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    final total = _parseDouble(decoded) ??
        (decoded is Map<String, dynamic>
            ? _parseDouble(decoded['total'] ?? decoded['value'])
            : null);
    if (total != null) return total;
    throw Exception('Format inattendu pour total-livree-hors-ligne: ${res.body}');
  }

  /// GET /commandes/transporteur/{idTransporteur}/pourcentage-sous-zone
  /// Retourne un map de sous-zone -> pourcentage (0-100)
  Future<Map<String, double>>
      getPourcentageRevenuParSousZoneLivreeByTransporteur(
    String idTransporteur,
  ) async {
    final res = await api.get(
      '$_base/transporteur/$idTransporteur/pourcentage-sous-zone',
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'GET $_base/transporteur/$idTransporteur/pourcentage-sous-zone -> ${res.statusCode}: ${res.body}',
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is Map) {
      return decoded.map<String, double>((key, value) {
        final pct = _parseDouble(value) ?? 0;
        return MapEntry(key.toString(), pct);
      });
    }
    throw Exception(
      'Format inattendu pour pourcentage-sous-zone: ${res.body}',
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }
}
