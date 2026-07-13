// --- Enums ---

enum Role { client, transporteur, admin }

enum Statut { actif, inactif, banni }

// --- Zones (assumant que vous n'avez pas besoin de Zone/SousZone, ou les simplifiant) ---
// Note: Si vous avez besoin d'utiliser les Zones, vous pouvez les définir ici.
// Par souci de simplicité et de concision, j'ai omis les longues énumérations Zone et SousZone,
// car elles ne sont pas nécessaires pour le corps de la classe Utilisateur.
// Si elles sont obligatoires, ajoutez-les ici.

// --- Modèle Utilisateur ---

class Utilisateur {
  final String? id;
  final String? nom;
  final String? prenom;
  final DateTime? dateNaissance; // LocalDate en Java -> DateTime en Dart

  final String? email;
  final String? motDePasse;
  final String? telephone;

  final Role role;

  final String? adresse;
  final String? image; // chemin/URL vers l'image de profil
  final Statut statut;

  final DateTime? dateCreation; // LocalDateTime en Java -> DateTime en Dart
  final DateTime? lastSeen;
  final bool online;
  final double? latitude;
  final double? longitude;

  // Assurez-vous d'utiliser String ou un modèle pour ces champs si nécessaire
  // final SousZone? sousZone;
  // final Zone? zone;

  Utilisateur({
    required this.id,
    this.nom,
    this.prenom,
    this.dateNaissance,
    this.email,
    this.motDePasse,
    this.telephone,
    this.role = Role.client,
    this.adresse,
    this.image,
    this.statut = Statut.actif,
    this.dateCreation,
    this.lastSeen,
    this.online = false,
    this.latitude,
    this.longitude,
    // this.sousZone,
    // this.zone,
  });

  // --- Factory pour désérialisation JSON ---
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les dates (Java LocalDate/LocalDateTime en ISO string)
    DateTime? parseDate(dynamic dateString) {
      if (dateString == null) return null;
      // Java LocalDate (ex: [2024, 1, 1]) ou ISO string
      if (dateString is List && dateString.length >= 3) {
        // Si le format est [year, month, day, hour, minute, second, nanosecond]
        return DateTime(
          dateString[0],
          dateString[1],
          dateString[2],
          dateString.length > 3 ? dateString[3] : 0,
          dateString.length > 4 ? dateString[4] : 0,
        );
      }
      if (dateString is String) {
        return DateTime.tryParse(dateString);
      }
      return null;
    }

    // Helper pour les enums
    Role parseRole(String? roleString) {
      if (roleString == null) return Role.client;
      try {
        return Role.values.firstWhere(
          (e) =>
              e.toString().split('.').last.toLowerCase() ==
              roleString.toLowerCase(),
          orElse: () => Role.client,
        );
      } catch (_) {
        return Role.client;
      }
    }

    Statut parseStatut(String? statutString) {
      if (statutString == null) return Statut.actif;
      try {
        return Statut.values.firstWhere(
          (e) =>
              e.toString().split('.').last.toLowerCase() ==
              statutString.toLowerCase(),
          orElse: () => Statut.actif,
        );
      } catch (_) {
        return Statut.actif;
      }
    }

    return Utilisateur(
      // Les clés JSON sont typiquement en camelCase ou snake_case
      // selon la configuration de Jackson/Gson dans Spring Boot.
      // J'utilise ici un mélange basé sur la convention.
      id: json['id'] as String?,
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,

      // dateNaissance peut être une String (ISO) ou un tableau [y, m, d]
      dateNaissance: parseDate(json['dateNaissance']),

      email: json['email'] as String?,
      motDePasse: json['motDePasse'] as String?,
      telephone: json['telephone'] as String?,

      role: parseRole(json['role'] as String?),

      adresse: json['adresse'] as String?,
      image: json['image'] as String?,
      statut: parseStatut(json['statut'] as String?),

      dateCreation: parseDate(json['dateCreation']),
      lastSeen: parseDate(json['lastSeen']),
      online: json['online'] as bool? ?? false,

      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  // --- Méthode pour sérialisation JSON (pour les requêtes POST/PUT) ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      // Dart DateTime -> ISO String
      'dateNaissance':
          dateNaissance?.toIso8601String().split('T').first, // LocalDate format
      'email': email,
      'motDePasse': motDePasse,
      'telephone': telephone,
      'role': role.toString().split('.').last, // 'client', 'transporteur', etc.
      'adresse': adresse,
      'image': image,
      'statut': statut.toString().split('.').last, // 'actif', 'inactif', etc.
      'dateCreation': dateCreation?.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'online': online,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
