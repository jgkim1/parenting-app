class Category {
  const Category({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
      );
}
