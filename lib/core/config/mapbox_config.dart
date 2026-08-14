import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Compile-time Mapbox configuration shared by every map implementation.
///
/// A local `.env` file supplies the normal development token. A Dart define
/// can override it for CI or production builds.
abstract final class MapboxConfig {
  static String get accessToken {
    const dartDefineToken = String.fromEnvironment('ACCESS_TOKEN');
    return dartDefineToken.trim().isNotEmpty
        ? dartDefineToken.trim()
        : (dotenv.env['ACCESS_TOKEN'] ?? '').trim();
  }

  static bool get hasValidAccessToken {
    final token = accessToken.trim();
    return token.startsWith('pk.') && token.length > 20;
  }

  static const String streetsStyleUri = 'mapbox://styles/mapbox/streets-v12';

  static String get webStreetsTileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/'
      '{z}/{x}/{y}{r}?access_token=$accessToken';
}
