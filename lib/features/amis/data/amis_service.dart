import 'dart:convert';

// Import your actual models here.
import 'package:yemchi_wyji/core/models/utilisateur.dart';
import 'package:yemchi_wyji/core/models/ami.dart';
import '../../../core/network/api.dart';
import 'package:yemchi_wyji/features/auth/data/auth_user_service.dart';
// import '../../../core/storage/token_storage.dart'; // Uncomment if needed for specific logic

class AmiService {
  final api = Api();
  static const String _baseUrl = '/amis';

  // GET /api/amis/{userId}/liste
  Future<List<Utilisateur>> getAmis(String userId) async {
    final url = '$_baseUrl/$userId/liste';
    print('DEBUG: Sending GET request to: $url'); // Debugging
    final response = await api.get(url);
    print('DEBUG: Received response for GET $url with status: ${response.statusCode}'); // Debugging

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Utilisateur.fromJson(e)).toList();
    }

    // Handle 404/204 gracefully if needed, otherwise throw
    if (response.statusCode == 404 || response.statusCode == 204) {
      return [];
    }

    throw Exception('Failed to load friends list');
  }

  // PUT /api/amis/accepter (Takes the whole Ami object)
  Future<Ami> accepter(Ami ami) async {
    final url = '$_baseUrl/accepter';
    print('DEBUG: Sending PUT request to: $url'); // Debugging
    final response = await api.put(
      url,
      body: jsonEncode(ami.toJson()),
    );
    print('DEBUG: Received response for PUT $url with status: ${response.statusCode}'); // Debugging

    if (response.statusCode == 200) {
      return Ami.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to accept friend request');
  }

  // PUT /api/amis/refuser (Takes the whole Ami object)
  Future<Ami> refuser(Ami ami) async {
    final url = '$_baseUrl/refuser';
    print('DEBUG: Sending PUT request to: $url'); // Debugging
    final response = await api.put(
      url,
      body: jsonEncode(ami.toJson()),
    );
    print('DEBUG: Received response for PUT $url with status: ${response.statusCode}'); // Debugging

    if (response.statusCode == 200) {
      return Ami.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to refuse friend request');
  }

  // POST /api/amis/inviter
  Future<Ami> inviter(String demandeurId, String recepteurId) async {
    final url = '$_baseUrl/inviter';
    final payload = {
      'utilisateur_demandeur': demandeurId,
      'utilisateur_recepteur': recepteurId,
    };
    print('DEBUG: Sending POST request to: $url with payload: $payload'); // Debugging
    final response = await api.post(
      url,
      body: jsonEncode(payload),
    );
    print('DEBUG: Received response for POST $url with status: ${response.statusCode}'); // Debugging

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Ami.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to send invitation');
  }

  // GET /api/amis/status
  Future<RelationStatusResponse> getStatus(String u1, String u2) async {
    final params = {'u1': u1, 'u2': u2};
    final queryString = Uri(queryParameters: params).query;
    final url = '$_baseUrl/status?$queryString';
    print('DEBUG: Sending GET request to: $url'); // Debugging
    final response = await api.get(url);
    print('DEBUG: Received response for GET $url with status: ${response.statusCode}'); // Debugging

    if (response.statusCode == 200) {
      return RelationStatusResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get status');
  }

  // GET /api/amis/invitations/recues/demandeurs
  Future<List<Utilisateur>> getReceivedInvitationSenders(String userId) async {
    final params = {'userId': userId};
    final queryString = Uri(queryParameters: params).query;
    final url = '$_baseUrl/invitations/recues/demandeurs?$queryString';
    print('DEBUG: Sending GET request to: $url'); // Debugging
    final response = await api.get(url);
    print('DEBUG: Received response for GET $url with status: ${response.statusCode}'); // Debugging

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Utilisateur.fromJson(e)).toList();
    }
    throw Exception('Failed to load received invitations');
  }

  // PUT /api/amis/accepter (By IDs)
  Future<void> accepterInvitationParUtilisateurs(String demandeurId, String recepteurId) async {
    final params = {
      'demandeurId': demandeurId,
      'recepteurId': recepteurId,
    };
    final queryString = Uri(queryParameters: params).query;
    final url = '$_baseUrl/accepter?$queryString';
    print('DEBUG: Sending PUT request to: $url'); // Debugging
    final response = await api.put(url, body: jsonEncode({}));
    print('DEBUG: Received response for PUT $url with status: ${response.statusCode}'); // Debugging
    
    if (response.statusCode != 200) {
      throw Exception('Failed to accept invitation by IDs');
    }
  }

  // PUT /api/amis/refuser (By IDs)
  Future<void> refuserInvitationParUtilisateurs(String demandeurId, String recepteurId) async {
    final params = {
      'demandeurId': demandeurId,
      'recepteurId': recepteurId,
    };
    final queryString = Uri(queryParameters: params).query;
    final url = '$_baseUrl/refuser?$queryString';
    print('DEBUG: Sending PUT request to: $url'); // Debugging
    final response = await api.put(url, body: jsonEncode({}));
    print('DEBUG: Received response for PUT $url with status: ${response.statusCode}'); // Debugging

    if (response.statusCode != 200) {
      throw Exception('Failed to refuse invitation by IDs');
    }
  }

  // ------------------------------------------------------------------
  // SEARCH METHODS
  // ------------------------------------------------------------------

  // Search by Numero
  Future<List<Utilisateur>> searchMyFriendsByNumero(String meId, String numero) async {
    return _performSearch('numero', {'me': meId, 'q': numero});
  }

  // Search by Nom
  Future<List<Utilisateur>> searchMyFriendsByNom(String meId, String nom) async {
    return _performSearch('nom', {'me': meId, 'q': nom});
  }

  // Search by Prenom
  Future<List<Utilisateur>> searchMyFriendsByPrenom(String meId, String prenom) async {
    return _performSearch('prenom', {'me': meId, 'q': prenom});
  }

  // Search by Nom OR Prenom
  Future<List<Utilisateur>> searchMyFriendsByNomPrenom(String meId, String q) async {
    return _performSearch('nom-prenom', {'me': meId, 'q': q});
  }

  // Search by Nom AND Prenom
  Future<List<Utilisateur>> searchMyFriendsByNomEtPrenom(String meId, String nom, String prenom) async {
    return _performSearch('nom-et-prenom', {'me': meId, 'nom': nom, 'prenom': prenom});
  }

  // Helper method for search requests to avoid code duplication
  Future<List<Utilisateur>> _performSearch(String endpointSuffix, Map<String, String> params) async {
    final queryString = Uri(queryParameters: params).query;
    final url = '$_baseUrl/search/mes-amis/$endpointSuffix?$queryString';
    print('DEBUG: Sending GET request to: $url'); // Debugging
    final response = await api.get(url);
    print('DEBUG: Received response for GET $url with status: ${response.statusCode}'); // Debugging
    
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => Utilisateur.fromJson(e)).toList();
    }
    throw Exception('Failed to search friends');
  }
}

// ------------------------------------------------------------------
// DATA TRANSFER OBJECTS (DTOs)
// ------------------------------------------------------------------

enum RelationStatus {
  NONE,
  EN_ATTENTE,
  EN_ATTENTE_RECU,
  ACCEPTE,
  REFUSE,
  UNKNOWN,
}

class RelationStatusResponse {
  final RelationStatus status;
  final String? invitationId;
  final Utilisateur? user;

  RelationStatusResponse({required this.status, this.invitationId, this.user});
  factory RelationStatusResponse.fromJson(Map<String, dynamic> json) {
    Utilisateur? parsedUser;
    final dynamic userJson =
        json['user'] ?? json['utilisateur'] ?? json['otherUser'] ?? json['utilisateur2'] ?? json['profil'];
    if (userJson is Map) {
      parsedUser = Utilisateur.fromJson(Map<String, dynamic>.from(userJson));
    }

    return RelationStatusResponse(
      status: _parseStatus((json['status']).toString()),
      invitationId: (json['invitationId'] ?? json['idInvitation'])?.toString(),
      user: parsedUser,
    );
  }

  static RelationStatus _parseStatus(String? status) {
    switch (status) {
      case 'NONE': return RelationStatus.NONE;
      case 'PENDING_SENT': return RelationStatus.EN_ATTENTE;
      case 'PENDING_RECEIVED': return RelationStatus.EN_ATTENTE_RECU;
      case 'ACCEPTED': return RelationStatus.ACCEPTE;
      case 'REFUSED': return RelationStatus.REFUSE;
      default: return RelationStatus.UNKNOWN;
    }
  }


  
}
