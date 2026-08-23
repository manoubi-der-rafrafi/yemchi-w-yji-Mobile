import 'package:flutter_test/flutter_test.dart';
import 'package:yemchi_wyji/core/media/product_image_url.dart';

void main() {
  group('ProductImageUrl.resolve', () {
    const publicSite = 'https://www.yemchi-w-yji.tn';

    test('conserve une URL HTTPS publique', () {
      expect(
        ProductImageUrl.resolve(
          'https://res.cloudinary.com/demo/image/upload/sample.jpg',
          publicSiteUrl: publicSite,
        ),
        'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      );
    });

    test('resout un ancien chemin relatif sur le site public', () {
      expect(
        ProductImageUrl.resolve(
          '/produits/mon image.jpg',
          publicSiteUrl: publicSite,
        ),
        'https://www.yemchi-w-yji.tn/produits/mon%20image.jpg',
      );
    });

    test('force HTTPS pour une ancienne URL HTTP', () {
      expect(
        ProductImageUrl.resolve(
          'http://cdn.example.com/image.jpg',
          publicSiteUrl: publicSite,
        ),
        'https://cdn.example.com/image.jpg',
      );
    });

    test('refuse les URLs locales et les schemes non reseau', () {
      expect(
        ProductImageUrl.resolve(
          'http://localhost:8080/image.jpg',
          publicSiteUrl: publicSite,
        ),
        isNull,
      );
      expect(
        ProductImageUrl.resolve(
          'file:///C:/images/image.jpg',
          publicSiteUrl: publicSite,
        ),
        isNull,
      );
    });

    test('refuse une valeur vide', () {
      expect(ProductImageUrl.resolve('  ', publicSiteUrl: publicSite), isNull);
    });
  });
}
