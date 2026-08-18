class ArticleCategory {
  const ArticleCategory({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory ArticleCategory.fromJson(Map<String, dynamic> json) => ArticleCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
      );
}
