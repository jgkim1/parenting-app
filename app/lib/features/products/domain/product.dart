import 'category.dart';

// 상품 목록에서 쓰는 요약 모델. 서버가 썸네일 1장(images[0])만 내려준다.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.isActive,
    this.thumbnailUrl,
  });

  final String id;
  final String name;
  final int price;
  final int stock;
  final Category category;
  // 공개 목록 응답에는 항상 활성 상품만 담기므로 없으면 true로 취급한다.
  final bool isActive;
  final String? thumbnailUrl;

  factory Product.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? [];
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      stock: json['stock'] as int,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool? ?? true,
      thumbnailUrl: images.isNotEmpty ? (images.first as Map<String, dynamic>)['url'] as String? : null,
    );
  }
}

class ProductPage {
  const ProductPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<Product> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory ProductPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>;
    return ProductPage(
      items: items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
