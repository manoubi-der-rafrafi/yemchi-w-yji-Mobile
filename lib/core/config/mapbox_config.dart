/// Compile-time Mapbox configuration shared by every map implementation.
///
/// Supply the public token with:
/// `flutter run --dart-define=ACCESS_TOKEN=pk...`
abstract final class MapboxConfig {
  static const String accessToken = String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue: '',
  );

  static bool get hasValidAccessToken {
    final token = accessToken.trim();
    return token.startsWith('pk.') && token.length > 20;
  }

  static const String streetsStyleUri = 'mapbox://styles/mapbox/streets-v12';

  static String get webStreetsTileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/'
      '{z}/{x}/{y}{r}?access_token=$accessToken';
}
