import 'comment.dart';

class PostDetail {
  const PostDetail({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.imageUrl,
    required this.viewCount,
    required this.createdAt,
    required this.authorId,
    required this.authorNickname,
    required this.likeCount,
    required this.likedByMe,
    required this.comments,
  });

  final String id;
  final String title;
  final String content;
  final String? category;
  final String? imageUrl;
  final int viewCount;
  final DateTime createdAt;
  final String authorId;
  final String authorNickname;
  final int likeCount;
  final bool likedByMe;
  final List<Comment> comments;

  PostDetail copyWith({
    int? likeCount,
    bool? likedByMe,
    List<Comment>? comments,
  }) {
    return PostDetail(
      id: id,
      title: title,
      content: content,
      category: category,
      imageUrl: imageUrl,
      viewCount: viewCount,
      createdAt: createdAt,
      authorId: authorId,
      authorNickname: authorNickname,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      comments: comments ?? this.comments,
    );
  }

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>;
    final comments = json['comments'] as List<dynamic>;
    return PostDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      viewCount: json['viewCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorId: author['id'] as String,
      authorNickname: author['nickname'] as String,
      likeCount: json['likeCount'] as int,
      likedByMe: json['likedByMe'] as bool,
      comments: comments.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
