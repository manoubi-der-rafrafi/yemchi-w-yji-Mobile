import 'package:yemchi_wyji/core/env.dart';

class ProductImageUrl {
  const ProductImageUrl._();

  static String? resolve(
    String? rawUrl, {
    String publicSiteUrl = Env.publicSiteUrl,
  }) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;

    var value = rawUrl.trim().replaceAll('\\', '/');
    if (value.startsWith('//')) value = 'https:$value';

    final parsed = Uri.tryParse(value);
    if (parsed == null) return null;

    if (!parsed.hasScheme) {
      final base = Uri.tryParse(
        publicSiteUrl.endsWith('/') ? publicSiteUrl : '$publicSiteUrl/',
      );
      if (base == null || base.host.isEmpty) return null;
      value = value.startsWith('/') ? value.substring(1) : value;
      return base.resolve(value).toString();
    }

    if (parsed.scheme != 'http' && parsed.scheme != 'https') return null;
    if (parsed.host.isEmpty || _isLocalHost(parsed.host)) return null;

    return parsed.replace(scheme: 'https').toString();
  }

  static bool _isLocalHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0' ||
        normalized == '10.0.2.2' ||
        normalized.endsWith('.local');
  }
}
