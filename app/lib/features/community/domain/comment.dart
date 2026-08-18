class Comment {
  const Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorNickname,
    required this.createdAt,
  });

  final String id;
  final String content;
  final String authorId;
  final String authorNickname;
  final DateTime createdAt;

  factory Comment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>;
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      authorId: author['id'] as String,
      authorNickname: author['nickname'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
