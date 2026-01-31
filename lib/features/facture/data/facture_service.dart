import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yemchi_wyji/core/env.dart';
import 'package:yemchi_wyji/core/models/facture.dart';
import 'package:yemchi_wyji/core/network/api.dart';
import 'package:yemchi_wyji/core/storage/token_storage.dart';
import 'package:yemchi_wyji/features/facture/dto/facture_dto.dart';

class FactureService {
  final Api _api;
  final String _base = '/factures';

  FactureService({Api? api}) : _api = api ?? Api();

  /// Creation d'une facture.
  Future<Facture> create(FactureDto dto) async {
    final r = await _api.post(
      _base,
      body: jsonEncode(dto.toMap()),
    );
    final body = _safeJsonDecode(r.body);
    if (body is Map<String, dynamic>) {
      return FactureDto.fromMap(body).toModel();
    }
    throw ApiException(
      r.statusCode,
      'Format de reponse inattendu a la creation',
    );
  }

  /// Creation d'une facture avec image (multipart/form-data).
  Future<Facture> createWithImage({
    required XFile image,
    required double montant,
    required String dateTimle,
    required String idLivreur,
    required FactureType type,
    bool confirmer = false,
  }) async {
    final token = await TokenStorage.access();
    final bytes = await image.readAsBytes();
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
    final mimeType = image.mimeType ?? 'image/jpeg';
    final parts = mimeType.split('/');
    final mediaType = parts.length == 2
        ? MediaType(parts[0], parts[1])
        : MediaType('image', 'jpeg');
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: image.name,
        contentType: mediaType,
      ),
      'montant': montant.toStringAsFixed(2),
      'dateTimle': dateTimle,
      'idLivreur': idLivreur,
      'type': type.value,
      'confirmer': confirmer.toString(),
    });
    final response = await dio.post(
      _base,
      data: formData,
    );
    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      throw ApiException(
        response.statusCode ?? 0,
        response.data?.toString() ?? 'Erreur upload',
      );
    }
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return FactureDto.fromMap(body).toModel();
    }
    throw ApiException(
      response.statusCode ?? 0,
      'Format de reponse inattendu a la creation (multipart)',
    );
  }

  Future<List<Facture>> listByLivreurId(String livreurId) async {
    final r = await _api.get('$_base/livreur/$livreurId');
    final body = _safeJsonDecode(r.body);
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((item) => FactureDto.fromMap(item).toModel())
          .toList();
    }
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => FactureDto.fromMap(item).toModel())
          .toList();
    }
    throw ApiException(
      r.statusCode,
      'Format de reponse inattendu pour la liste',
    );
  }

  Future<double> sumMontantEntrepriseVerseLivreurByLivreurId(
    String livreurId,
  ) async {
    final r = await _api.get(
      '$_base/livreur/$livreurId/sum-entreprise-verse-livreur',
    );
    final body = _safeJsonDecode(r.body);
    final total = _parseDouble(body) ??
        (body is Map<String, dynamic>
            ? _parseDouble(body['total'] ?? body['value'])
            : null);
    if (total != null) return total;
    throw ApiException(
      r.statusCode,
      'Format de reponse inattendu pour le total entreprise->livreur',
    );
  }

  Future<double> sumMontantLivreurVerseEntrepriseByLivreurId(
    String livreurId,
  ) async {
    final r = await _api.get(
      '$_base/livreur/$livreurId/sum-livreur-verse-entreprise',
    );
    final body = _safeJsonDecode(r.body);
    final total = _parseDouble(body) ??
        (body is Map<String, dynamic>
            ? _parseDouble(body['total'] ?? body['value'])
            : null);
    if (total != null) return total;
    throw ApiException(
      r.statusCode,
      'Format de reponse inattendu pour le total livreur->entreprise',
    );
  }

  dynamic _safeJsonDecode(String source) {
    try {
      return json.decode(source);
    } catch (_) {
      return source;
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }
}
