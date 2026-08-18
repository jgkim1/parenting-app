import 'category.dart';

class ProductReview {
  const ProductReview({
    required this.id,
    required this.rating,
    required this.content,
    required this.authorId,
    required this.authorNickname,
  });

  final String id;
  final int rating;
  final String content;
  final String authorId;
  final String authorNickname;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return ProductReview(
      id: json['id'] as String,
      rating: json['rating'] as int,
      content: json['content'] as String,
      authorId: user['id'] as String,
      authorNickname: user['nickname'] as String,
    );
  }
}

class ReviewStats {
  const ReviewStats({required this.average, required this.count});

  final double average;
  final int count;

  factory ReviewStats.fromJson(Map<String, dynamic> json) => ReviewStats(
        average: (json['average'] as num).toDouble(),
        count: json['count'] as int,
      );
}

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.sellerNickname,
    required this.imageUrls,
    required this.reviews,
    required this.reviewStats,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final int stock;
  final Category category;
  final String sellerNickname;
  final List<String> imageUrls;
  final List<ProductReview> reviews;
  final ReviewStats reviewStats;
  final bool isActive;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? [];
    final reviews = json['reviews'] as List<dynamic>? ?? [];
    return ProductDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      stock: json['stock'] as int,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      sellerNickname: (json['seller'] as Map<String, dynamic>)['nickname'] as String,
      imageUrls: images.map((e) => (e as Map<String, dynamic>)['url'] as String).toList(),
      reviews: reviews.map((e) => ProductReview.fromJson(e as Map<String, dynamic>)).toList(),
      reviewStats: ReviewStats.fromJson(json['reviewStats'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
