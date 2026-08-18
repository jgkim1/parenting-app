import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/products/domain/category.dart';
import 'package:parenting_app/features/products/domain/product.dart';

Map<String, dynamic> _categoryJson() => {'id': 'c1', 'name': '완구/교육', 'slug': 'toys-education'};

Map<String, dynamic> _productJson({List<dynamic>? images}) => {
      'id': 'p1',
      'name': '원목 딸랑이',
      'price': 15900,
      'stock': 200,
      'category': _categoryJson(),
      'images': images ?? [],
    };

void main() {
  group('Category.fromJson', () {
    test('필드를 그대로 매핑한다', () {
      final category = Category.fromJson(_categoryJson());
      expect(category.id, 'c1');
      expect(category.name, '완구/교육');
      expect(category.slug, 'toys-education');
    });
  });

  group('Product.fromJson', () {
    test('images가 있으면 첫 번째 이미지를 썸네일로 쓴다', () {
      final product = Product.fromJson(_productJson(images: [
        {'url': 'https://example.com/a.png'},
        {'url': 'https://example.com/b.png'},
      ]));

      expect(product.thumbnailUrl, 'https://example.com/a.png');
      expect(product.name, '원목 딸랑이');
      expect(product.price, 15900);
      expect(product.stock, 200);
      expect(product.category.name, '완구/교육');
    });

    test('images가 비어 있으면 썸네일은 null이다', () {
      final product = Product.fromJson(_productJson(images: []));
      expect(product.thumbnailUrl, isNull);
    });

    test('images 키 자체가 없어도 예외 없이 처리한다', () {
      final json = _productJson()..remove('images');
      final product = Product.fromJson(json);
      expect(product.thumbnailUrl, isNull);
    });
  });

  group('ProductPage.fromJson', () {
    test('items/page/totalPages를 매핑하고 hasMore를 계산한다', () {
      final page = ProductPage.fromJson({
        'items': [_productJson(), _productJson()],
        'page': 1,
        'totalPages': 3,
      });

      expect(page.items, hasLength(2));
      expect(page.page, 1);
      expect(page.totalPages, 3);
      expect(page.hasMore, isTrue);
    });

    test('마지막 페이지면 hasMore가 false다', () {
      final page = ProductPage.fromJson({'items': [], 'page': 3, 'totalPages': 3});
      expect(page.hasMore, isFalse);
    });
  });
}
