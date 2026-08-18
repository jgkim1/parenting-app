import 'article_category.dart';

// 아티클 목록에서 쓰는 요약 모델.
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.category,
    required this.createdAt,
    required this.isActive,
  });

  final String id;
  final String title;
  final String? thumbnailUrl;
  final ArticleCategory category;
  final DateTime createdAt;
  // 공개 목록 응답에는 항상 공개 아티클만 담기므로 없으면 true로 취급한다.
  final bool isActive;

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String,
        title: json['title'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        category: ArticleCategory.fromJson(json['category'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );
}

class ArticlePage {
  const ArticlePage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<Article> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory ArticlePage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>;
    return ArticlePage(
      items: items.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
