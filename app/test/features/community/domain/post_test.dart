import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/community/domain/post.dart';

Map<String, dynamic> _postJson({String? imageUrl, int comments = 0, int likes = 0}) => {
      'id': 'post1',
      'title': '밤중 수유 언제까지 하셨나요',
      'category': '질문',
      'imageUrl': imageUrl,
      'viewCount': 2,
      'createdAt': '2026-08-14T00:00:00.000Z',
      'author': {'id': 'u1', 'nickname': '테스터'},
      '_count': {'comments': comments, 'likes': likes},
    };

void main() {
  group('Post.fromJson', () {
    test('_count에서 commentCount/likeCount를 꺼낸다', () {
      final post = Post.fromJson(_postJson(comments: 3, likes: 5));
      expect(post.commentCount, 3);
      expect(post.likeCount, 5);
      expect(post.authorNickname, '테스터');
    });

    test('category/imageUrl이 null이어도 처리한다', () {
      final json = _postJson()
        ..['category'] = null
        ..['imageUrl'] = null;
      final post = Post.fromJson(json);
      expect(post.category, isNull);
      expect(post.imageUrl, isNull);
    });
  });

  group('PostPage.fromJson', () {
    test('items/page/totalPages를 매핑한다', () {
      final page = PostPage.fromJson({
        'items': [_postJson(), _postJson()],
        'page': 1,
        'totalPages': 1,
      });
      expect(page.items, hasLength(2));
      expect(page.hasMore, isFalse);
    });
  });
}
