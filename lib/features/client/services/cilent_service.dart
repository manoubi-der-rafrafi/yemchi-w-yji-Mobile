import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produit.dart';

class ProduitService {
  static const String _baseUrl = 'https://yemchi-w-yji-back-1.onrender.com/api/produits';

  // GET /produits
  Future<List<Produit>> getAll() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Produit.fromJson(e)).toList();
    }
    throw Exception('Erreur lors du chargement des produits');
  }

  // GET /produits/:id
  Future<Produit> getById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/$id'));
    if (response.statusCode == 200) {
      return Produit.fromJson(jsonDecode(response.body));
    }
    throw Exception("Erreur lors du chargement du produit");
  }

  // GET /produits/commande/:idCommande
  Future<List<Produit>> getByCommande(String idCommande) async {
    final response = await http.get(Uri.parse('$_baseUrl/commande/$idCommande'));
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Produit.fromJson(e)).toList();
    }
    throw Exception("Erreur lors du chargement des produits par commande");
  }

  // POST /produits
  Future<Produit> create(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Produit.fromJson(jsonDecode(response.body));
    }
    throw Exception("Erreur lors de la création du produit");
  }

  // PUT /produits/:id
  Future<Produit> update(String id, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return Produit.fromJson(jsonDecode(response.body));
    }
    throw Exception("Erreur lors de la mise à jour du produit");
  }

  // DELETE /produits/:id
  Future<void> delete(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$id'));
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw Exception("Erreur lors de la suppression du produit");
  }

  // GET /produits/search?nom=...&type=...
  Future<List<Produit>> search({String? nom, String? type}) async {
    final params = <String, String>{};
    if (nom != null) params['nom'] = nom;
    if (type != null) params['type'] = type;

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Produit.fromJson(e)).toList();
    }
    throw Exception("Erreur lors de la recherche des produits");
  }

  // POST /produits/upload
  Future<String> uploadProduitImage(String filePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', filePath));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['success'] == true && decoded['url'] != null) {
        return decoded['url'];
      } else {
        throw Exception('Erreur: ${decoded['message']}');
      }
    }
    throw Exception('Erreur lors de l\'envoi de l\'image');
  }
}
