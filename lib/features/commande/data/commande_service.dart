// lib/features/commande/data/commande_service.dart
import 'dart:convert';

import 'package:yemchi_wyji/core/models/commande.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/features/commande/dto/commande_dto.dart';
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
  /// Exemple: zone = "GRAND_TUNIS", "COTIER_NORD", "CENTRE_EST", "SFAX", "SUD_EST", "INTERIEUR"
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

  Future<Commande> assignerTransporteur(String idCommande, String idTransporteur) async {
  final res = await api.put('/commandes/$idCommande/assigner/$idTransporteur', body: '{}');
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('PUT /commandes/$idCommande/assigner/$idTransporteur -> ${res.statusCode}: ${res.body}');
  }
  final map = json.decode(res.body) as Map<String, dynamic>;
  return Commande.fromJson(map);
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
}
