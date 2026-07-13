import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produit.dart';
import '../models/commande.dart';
import '../../../core/network/api.dart';
import '../../../core/env.dart';
import '../../../core/storage/token_storage.dart';

class CommandeService {
  final api = Api();
  static const String _baseUrl = '/commandes';

  // GET /commandes/client/:userId/en_cours
  Future<Commande?> getActiveCommandeByUserId(String userId) async {
    final response = await api.get('$_baseUrl/client/$userId/en_cours');
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return Commande.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // POST /commandes
  Future<Commande> createCommandeForUser(String userId) async {
    final payload = {'statut': 'en_cours', 'clientId': userId};
    final response = await api.post(_baseUrl, body: jsonEncode(payload));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Commande.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erreur lors de la création de la commande');
  }

  Future<Commande> updateCommande(
    String commandeId,
    Map<String, dynamic> payload,
  ) async {
    // La méthode HTTP 'PUT' ou 'PATCH' est utilisée pour la mise à jour d'une ressource existante
    final response = await api.put(
      // to change to patch
      '$_baseUrl/$commandeId',
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return Commande.fromJson(jsonDecode(response.body));
    }
    // Inclure le corps de la réponse d'erreur pour le debug
    throw Exception(
      'Erreur lors de la mise à jour de la commande (${response.statusCode}): ${response.body}',
    );
  }
  //add api.patch

  // GET active commande or create if not found
  Future<Commande> getOrCreateActiveCommande(String userId) async {
    try {
      final response = await api.get('$_baseUrl/client/$userId/en_cours');

      // CAS 1: Commande active trouvée (Code 200, Body non vide)
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return Commande.fromJson(jsonDecode(response.body));
      }

      // CAS 2: Erreur de l'API (excluant 404 si votre méthode api.get gère 404)
      if (response.statusCode != 200 && response.statusCode != 404) {
        throw Exception(
          'Erreur API (${response.statusCode}) lors de la recherche de commande active: ${response.body}',
        );
      }

      // CAS 3: Commande non trouvée (ou statut 200 avec body vide, ou 404 si l'API ne l'a pas catché)
      // On force la création
      return await createCommandeForUser(userId);
    } on Exception catch (e) {
      // Si votre méthode api.get lance une exception interne (ex: Timeout, No Internet, ou 404)
      // Vous devez vérifier si l'exception est due au 404.
      // Si l'exception est due à un 404 (ce qui est le cas le plus probable ici), on crée.
      // SANS avoir le code de votre classe Api, on ne peut pas être certain,
      // mais on peut tester la chaîne de caractères si elle contient "404" ou "Not Found".
      final errorString = e.toString();
      if (errorString.contains('404') ||
          errorString.toLowerCase().contains('not found')) {
        print("Commande non trouvée (404), création d'une nouvelle.");
        return await createCommandeForUser(userId);
      }

      // Si c'est une autre erreur (réseau, authentification 401, 500, etc.), relancez.
      throw Exception(
        'Erreur inattendue lors du chargement de la commande: $errorString',
      );
    }
  }

  // PUT /commandes/:id/confirmer
  Future<Commande> confirmerCommande(String commandeId) async {
    final response = await api.put('$_baseUrl/$commandeId/confirmer');
    if (response.statusCode == 200) {
      return Commande.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erreur lors de la confirmation de la commande');
  }

  // DELETE /commandes/:id
  Future<void> deleteCommande(String commandeId) async {
    final response = await api.delete('$_baseUrl/$commandeId');
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw Exception('Erreur lors de la suppression de la commande');
  }

  Future<List<Commande>> getByClient(String clientId) async {
    final response = await api.get('$_baseUrl/client/$clientId');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Commande.fromJson(e)).toList();
    }
    // Si 404/204, retourne une liste vide au lieu de lancer une exception
    if (response.statusCode == 404 || response.statusCode == 204) {
      return [];
    }
    throw Exception(
      'Erreur lors du chargement des commandes client: ${response.statusCode}',
    );
  }

  // NOUVEAU: 2. Récupère les commandes où l'utilisateur est l'ami/destinataire
  // GET /commandes/amie/:amieId
  Future<List<Commande>> getByIdAmie(String amieId) async {
    final response = await api.get('$_baseUrl/amie/$amieId');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Commande.fromJson(e)).toList();
    }
    if (response.statusCode == 404 || response.statusCode == 204) {
      return [];
    }
    throw Exception(
      'Erreur lors du chargement des commandes amie: ${response.statusCode}',
    );
  }
}

class ProduitService {
  final api = Api();
  static const String _baseUrl = '/produits';

  // GET /produits
  Future<List<Produit>> getAll() async {
    final response = await api.get(_baseUrl);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Produit.fromJson(e)).toList();
    }
    throw Exception('Erreur lors du chargement des produits');
  }

  // GET /produits/:id
  Future<Produit> getById(String id) async {
    final response = await api.get('$_baseUrl/$id');
    if (response.statusCode == 200) {
      return Produit.fromJson(jsonDecode(response.body));
    }
    throw Exception("Erreur lors du chargement du produit");
  }

  // POST /produits
  Future<Produit> create(Map<String, dynamic> payload) async {
    final response = await api.post(_baseUrl, body: jsonEncode(payload));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Produit.fromJson(jsonDecode(response.body));
    }
    throw Exception("Erreur lors de la création du produit");
  }

  // PUT /produits/:id
  Future<Produit> update(String id, Map<String, dynamic> payload) async {
    final response = await api.put('$_baseUrl/$id', body: jsonEncode(payload));
    if (response.statusCode == 200) {
      return Produit.fromJson(jsonDecode(response.body));
    }
    throw Exception("Erreur lors de la mise à jour du produit");
  }

  // DELETE /produits/:id
  Future<void> delete(String id) async {
    final response = await api.delete('$_baseUrl/$id');
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

    // Construct the query parameters manually for the GET request
    final queryString = Uri(queryParameters: params).query;
    final endpoint =
        queryString.isNotEmpty
            ? '$_baseUrl/search?$queryString'
            : '$_baseUrl/search';

    final response = await api.get(endpoint);
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Produit.fromJson(e)).toList();
    }
    throw Exception("Erreur lors de la recherche des produits");
  }

  // GET /produits/commande/:idCommande
  Future<List<Produit>> getByCommande(String idCommande) async {
    final response = await api.get('$_baseUrl/commande/$idCommande');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Produit.fromJson(e)).toList();
    }
    throw Exception("Erreur lors du chargement des produits par commande");
  }

  // --- Helper Methods for Cart Flow ---

  // Get products for user's active cart (creates one if missing)
  Future<List<Produit>> getProduitsForActiveCommandeByUserId(
    String userId,
  ) async {
    final commandeService = CommandeService();

    // Step 1: Get or create active commande
    final commande = await commandeService.getOrCreateActiveCommande(userId);

    // Step 2: Get products for that commande
    return getByCommande(commande.id);
  }

  // Add a product to the user's active cart
  Future<Produit> addProduitForUser({
    required String userId,
    required Map<String, dynamic> formPayload,
    String? imagePath,
  }) async {
    // 1. Get or create active commande for user
    final commande = await CommandeService().getOrCreateActiveCommande(userId);

    // 2. Upload image if provided
    if (imagePath != null && imagePath.isNotEmpty) {
      final url = await uploadProduitImageAuth(imagePath);
      formPayload['image1'] =
          url; // Matches backend "Produit.imageUrl" convention if field is image1
    }

    // 3. Attach commandeId
    formPayload['commandeId'] = commande.id;

    // 4. Create produit
    return create(formPayload);
  }

  // Upload image to /api/produits/upload with Authorization header
  Future<String> uploadProduitImageAuth(String filePath) async {
    // Ensure we use the correct full URL
    final uri = Uri.parse('${Env.baseUrl}/produits/upload');
    final token = await TokenStorage.access();

    final request = http.MultipartRequest('POST', uri);

    // Add auth header manually because MultipartRequest doesn't use the Api interceptor
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    // 'image' matches @RequestParam("image") in Spring Boot controller
    request.files.add(await http.MultipartFile.fromPath('image', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Handle the specific response format from your controller:
      // return ResponseEntity.ok(Map.of("success", true, "url", url, ...));
      if (decoded is Map &&
          decoded['success'] == true &&
          decoded['url'] != null) {
        return decoded['url'].toString();
      }
      if (decoded is Map && decoded['message'] != null) {
        throw Exception('Erreur backend: ${decoded['message']}');
      }
    }
    throw Exception('Upload echoue (${response.statusCode}): ${response.body}');
  }
}
