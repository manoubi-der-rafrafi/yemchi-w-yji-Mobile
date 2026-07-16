// lib/core/models/ami.dart
import 'dart:convert';

/// Modèle aligné 1:1 avec le backend Java `Ami`.
/// ⚠️ AUCUN champ en plus.
/// Champs backend couverts :
/// id, demandeurId, recepteurId, statut, creeLe, majLe.
class Ami {
  // Identité (Mongo uses String/ObjectId)
  final String id;

  // Relations (IDs simples au lieu de @ManyToOne)
  final String? demandeurId;
  final String? recepteurId;

  // Métier
  final String? statut; // enum Java (EN_ATTENTE, etc.) -> String ici

  // Dates (LocalDateTime côté Java)
  final DateTime? creeLe;
  final DateTime? majLe;

  const Ami({
    required this.id,
    this.demandeurId,
    this.recepteurId,
    this.statut,
    this.creeLe,
    this.majLe,
  });

  // -------- Helpers de parsing sûrs --------
  static DateTime? _toDate(dynamic v) {
    if (v == null || (v is String && v.trim().isEmpty)) return null;
    return DateTime.tryParse(v.toString());
  }

  static String? _toStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  // -------- Parsing tolérant (alias snake/camel/legacy) --------
  factory Ami.fromJson(Map<String, dynamic> raw) {
    String _pickId(Map<String, dynamic> m) =>
        (m['id'] ?? m['_id'] ?? '').toString();

    T? _pick<T>(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) return m[k] as T?;
      }
      return null;
    }

    return Ami(
      id: _pickId(raw),

      // IDs : check camelCase, snake_case, et les clés payload spécifiques (utilisateur_x)
      demandeurId: _toStringOrNull(
        _pick(raw, ['demandeurId', 'demandeur_id', 'utilisateur_demandeur']),
      ),
      recepteurId: _toStringOrNull(
        _pick(raw, ['recepteurId', 'recepteur_id', 'utilisateur_recepteur']),
      ),

      // Enum -> String
      statut: _toStringOrNull(_pick(raw, ['statut', 'statutAmi', 'statut_ami'])),

      // Dates
      creeLe: _toDate(_pick(raw, ['creeLe', 'cree_le'])),
      majLe: _toDate(_pick(raw, ['majLe', 'maj_le'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'demandeurId': demandeurId,
        'recepteurId': recepteurId,
        'statut': statut,
        'creeLe': creeLe?.toIso8601String(),
        'majLe': majLe?.toIso8601String(),
      };

  static Ami fromJsonString(String jsonStr) =>
      Ami.fromJson(json.decode(jsonStr) as Map<String, dynamic>);

  Ami copyWith({
    String? id,
    String? demandeurId,
    String? recepteurId,
    String? statut,
    DateTime? creeLe,
    DateTime? majLe,
  }) {
    return Ami(
      id: id ?? this.id,
      demandeurId: demandeurId ?? this.demandeurId,
      recepteurId: recepteurId ?? this.recepteurId,
      statut: statut ?? this.statut,
      creeLe: creeLe ?? this.creeLe,
      majLe: majLe ?? this.majLe,
    );
  }
}