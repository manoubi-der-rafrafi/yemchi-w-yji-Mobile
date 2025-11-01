// lib/features/produit/data/produit_service.dart
// Service d'accès API pour la ressource Produit
// — S'appuie sur core/network/api.dart (gestion baseUrl, headers JWT, erreurs)

import 'dart:convert';

import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/core/models/produit.dart';
import 'package:yemchi_wyji/features/produit/dto/produit_dto.dart';

class ProduitService {
  final Api _api;
  final String _base = '/produits';

  ProduitService({Api? api}) : _api = api ?? Api();

  /// Récupération paginée/filtrée (optionnelle).
  /// Si votre backend renvoie un tableau simple => on le gère.
  /// Si votre backend renvoie un objet paginé { content: [...], totalElements, ... } => on le gère aussi.
  Future<List<Produit>> getAll({int? page, int? size, String? search}) async {
    final qs = _buildQuery({
      if (page != null) 'page': '$page',
      if (size != null) 'size': '$size',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });

    final r = await _api.get('$_base$qs');
    final body = _safeJsonDecode(r.body);

    if (body is List) {
      return body
          .map((e) => ProduitDTO.fromMap(e as Map<String, dynamic>).toModel())
          .toList();
    }

    if (body is Map && body['content'] is List) {
      final List content = body['content'];
      return content
          .map((e) => ProduitDTO.fromMap(e as Map<String, dynamic>).toModel())
          .toList();
    }

    // Cas non reconnu
    throw ApiException(r.statusCode, 'Format de réponse inattendu pour GET $_base');
  }

  Future<Produit> getById(String id) async {
    final r = await _api.get('$_base/$id');
    final body = _safeJsonDecode(r.body);
    if (body is Map<String, dynamic>) {
      return ProduitDTO.fromMap(body).toModel();
    }
    throw ApiException(r.statusCode, 'Produit introuvable ou format inattendu');
  }

  Future<Produit> create(ProduitDTO dto) async {
    final r = await _api.post(
      _base,
      body: jsonEncode(dto.toMap()),
    );
    final body = _safeJsonDecode(r.body);
    if (body is Map<String, dynamic>) {
      return ProduitDTO.fromMap(body).toModel();
    }
    throw ApiException(r.statusCode, 'Format de réponse inattendu à la création');
  }

  Future<Produit> update(String id, ProduitDTO dto) async {
    final r = await _api.put(
      '$_base/$id',
      body: jsonEncode(dto.toMap()),
    );
    final body = _safeJsonDecode(r.body);
    if (body is Map<String, dynamic>) {
      return ProduitDTO.fromMap(body).toModel();
    }
    throw ApiException(r.statusCode, 'Format de réponse inattendu à la mise à jour');
  }

  Future<void> delete(String id) async {
    // Beaucoup de backends renvoient 204 No Content
    await _api.put('$_base/$id?deleted=true');
    // \^ Si votre backend supporte plutôt DELETE, remplacez par :
    // await _api.delete('$_base/$id');
  }

  // =============================
  // Helpers
  // =============================

  String _buildQuery(Map<String, String> params) {
    if (params.isEmpty) return '';
    final qp = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '?$qp';
  }

  dynamic _safeJsonDecode(String source) {
    try {
      return json.decode(source);
    } catch (_) {
      return source; // laisser le ApiException afficher le body brut dans les logs
    }
  }
}
