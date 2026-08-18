// 게시글 목록에서 쓰는 요약 모델.
class Post {
  const Post({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.viewCount,
    required this.createdAt,
    required this.authorNickname,
    required this.commentCount,
    required this.likeCount,
  });

  final String id;
  final String title;
  final String? category;
  final String? imageUrl;
  final int viewCount;
  final DateTime createdAt;
  final String authorNickname;
  final int commentCount;
  final int likeCount;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String?,
        imageUrl: json['imageUrl'] as String?,
        viewCount: json['viewCount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        authorNickname: (json['author'] as Map<String, dynamic>)['nickname'] as String,
        commentCount: (json['_count'] as Map<String, dynamic>)['comments'] as int,
        likeCount: (json['_count'] as Map<String, dynamic>)['likes'] as int,
      );
}

class PostPage {
  const PostPage({required this.items, required this.page, required this.totalPages});

  final List<Post> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory PostPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>;
    return PostPage(
      items: items.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
