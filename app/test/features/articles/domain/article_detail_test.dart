import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/articles/domain/article_detail.dart';

void main() {
  group('ArticleDetail.fromJson', () {
    test('author.nickname을 authorNickname으로 매핑한다', () {
      final detail = ArticleDetail.fromJson({
        'id': 'a1',
        'title': '영유아 필수 예방접종 일정 정리',
        'content': '국가필수예방접종은...',
        'thumbnailUrl': 'https://example.com/thumb.png',
        'category': {'id': 'c1', 'name': '건강/예방접종', 'slug': 'health-vaccination'},
        'author': {'id': 'admin1', 'nickname': '육아앱 편집팀'},
        'viewCount': 3,
        'createdAt': '2026-08-14T00:00:00.000Z',
      });

      expect(detail.authorNickname, '육아앱 편집팀');
      expect(detail.category.name, '건강/예방접종');
      expect(detail.viewCount, 3);
      expect(detail.thumbnailUrl, 'https://example.com/thumb.png');
    });
  });
}
