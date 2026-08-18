import 'article_category.dart';

class ArticleDetail {
  const ArticleDetail({
    required this.id,
    required this.title,
    required this.content,
    required this.thumbnailUrl,
    required this.category,
    required this.authorNickname,
    required this.viewCount,
    required this.createdAt,
    required this.isActive,
  });

  final String id;
  final String title;
  final String content;
  final String? thumbnailUrl;
  final ArticleCategory category;
  final String authorNickname;
  final int viewCount;
  final DateTime createdAt;
  final bool isActive;

  factory ArticleDetail.fromJson(Map<String, dynamic> json) => ArticleDetail(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        category: ArticleCategory.fromJson(json['category'] as Map<String, dynamic>),
        authorNickname: (json['author'] as Map<String, dynamic>)['nickname'] as String,
        viewCount: json['viewCount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
      );
}
