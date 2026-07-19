import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:yemchi_wyji/core/network/api.dart';

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.duration,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final Duration duration;
}

class RouteService {
  RouteService({Api? api, http.Client? fallbackClient})
    : _api = api ?? Api(),
      _fallbackClient = fallbackClient ?? http.Client();

  final Api _api;
  final http.Client _fallbackClient;

  Future<RouteResult> fetchRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      return await _fetchBackendRoute(start: start, end: end);
    } catch (_) {
      return _fetchOsrmRoute(start: start, end: end);
    }
  }

  Future<RouteResult> _fetchBackendRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final response = await _api.post(
      '/routing/geometry',
      body: jsonEncode({
        'lat1': start.latitude,
        'lon1': start.longitude,
        'lat2': end.latitude,
        'lon2': end.longitude,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawCoordinates = data['coordinates'] as List<dynamic>? ?? const [];
    final points = rawCoordinates
        .whereType<Map>()
        .map(
          (point) => LatLng(
            (point['lat'] as num).toDouble(),
            (point['lng'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
    final km = (data['km'] as num?)?.toDouble() ?? 0;
    final minutes = (data['min'] as num?)?.round() ?? 0;
    return _validatedResult(
      points: points,
      distanceMeters: km * 1000,
      duration: Duration(minutes: minutes),
    );
  }

  Future<RouteResult> _fetchOsrmRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
    ).replace(
      queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );
    final response = await _fallbackClient
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Service de routage routier indisponible');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty || routes.first is! Map) {
      throw Exception('Aucun itineraire routier disponible');
    }
    final route = Map<String, dynamic>.from(routes.first as Map);
    final geometry = route['geometry'] as Map<String, dynamic>?;
    final rawCoordinates =
        geometry?['coordinates'] as List<dynamic>? ?? const [];
    final points = rawCoordinates
        .whereType<List>()
        .where((coordinate) => coordinate.length >= 2)
        .map(
          (coordinate) => LatLng(
            (coordinate[1] as num).toDouble(),
            (coordinate[0] as num).toDouble(),
          ),
        )
        .toList(growable: false);
    final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
    final durationSeconds = (route['duration'] as num?)?.round() ?? 0;
    return _validatedResult(
      points: points,
      distanceMeters: distanceMeters,
      duration: Duration(seconds: durationSeconds),
    );
  }

  RouteResult _validatedResult({
    required List<LatLng> points,
    required double distanceMeters,
    required Duration duration,
  }) {
    if (points.length < 3 || distanceMeters <= 0 || duration <= Duration.zero) {
      throw Exception('Geometrie routiere invalide');
    }
    return RouteResult(
      points: points,
      distanceMeters: distanceMeters,
      duration: duration,
    );
  }
}
