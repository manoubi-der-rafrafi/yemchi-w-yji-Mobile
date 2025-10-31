import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Lightweight wrapper around the public OSRM routing API.
class RouteService {
  RouteService({Dio? client})
      : _client = client ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _client;

  static const _baseUrl = 'https://router.project-osrm.org';

  /// Returns a list of points describing a scooter-friendly route between
  /// [start] and [end]. We rely on the OSRM `driving` profile which works
  /// well for scooters (roads + sens de circulation).
  Future<List<LatLng>> fetchRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final url =
        '$_baseUrl/route/v1/driving/${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}';

    final response = await _client.get(
      url,
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Erreur OSRM (${response.statusCode})');
    }

    final data = response.data as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw Exception('Aucun itinéraire disponible');
    }

    final geometry = routes.first['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.isEmpty) {
      throw Exception('Géométrie de trajet vide');
    }

    return coordinates
        .map(
          (coord) => LatLng(
            (coord[1] as num).toDouble(),
            (coord[0] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }
}
