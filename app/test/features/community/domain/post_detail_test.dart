import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/community/domain/comment.dart';
import 'package:parenting_app/features/community/domain/post_detail.dart';

Map<String, dynamic> _commentJson({String id = 'c1'}) => {
      'id': id,
      'content': '저도 궁금해요',
      'author': {'id': 'u2', 'nickname': '댓글러'},
      'createdAt': '2026-08-14T00:00:00.000Z',
    };

Map<String, dynamic> _postDetailJson({List<dynamic>? comments}) => {
      'id': 'post1',
      'title': '제목',
      'content': '내용',
      'category': '자유',
      'imageUrl': null,
      'viewCount': 1,
      'createdAt': '2026-08-14T00:00:00.000Z',
      'author': {'id': 'u1', 'nickname': '작성자'},
      'likeCount': 0,
      'likedByMe': false,
      'comments': comments ?? [],
    };

void main() {
  group('Comment.fromJson', () {
    test('author.id/nickname을 매핑한다', () {
      final comment = Comment.fromJson(_commentJson());
      expect(comment.authorId, 'u2');
      expect(comment.authorNickname, '댓글러');
      expect(comment.content, '저도 궁금해요');
    });
  });

  group('PostDetail.fromJson', () {
    test('댓글 목록과 좋아요 상태를 매핑한다', () {
      final detail = PostDetail.fromJson(_postDetailJson(comments: [_commentJson()]));
      expect(detail.authorNickname, '작성자');
      expect(detail.comments, hasLength(1));
      expect(detail.likedByMe, isFalse);
    });
  });

  group('PostDetail.copyWith', () {
    test('지정한 필드만 바뀌고 나머지는 유지된다', () {
      final original = PostDetail.fromJson(_postDetailJson());

      final liked = original.copyWith(likedByMe: true, likeCount: 1);
      expect(liked.likedByMe, isTrue);
      expect(liked.likeCount, 1);
      expect(liked.title, original.title);
      expect(liked.comments, original.comments);

      final withComment = original.copyWith(comments: [_commentJson()].map(Comment.fromJson).toList());
      expect(withComment.comments, hasLength(1));
      expect(withComment.likeCount, original.likeCount);
    });
  });
}
