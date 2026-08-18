import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/articles/domain/article.dart';
import 'package:parenting_app/features/articles/domain/article_category.dart';

Map<String, dynamic> _categoryJson() => {'id': 'c1', 'name': '이유식/영양', 'slug': 'nutrition'};

Map<String, dynamic> _articleJson({String? thumbnailUrl}) => {
      'id': 'a1',
      'title': '이유식 시작 시기와 순서 가이드',
      'thumbnailUrl': thumbnailUrl,
      'category': _categoryJson(),
      'createdAt': '2026-08-14T00:00:00.000Z',
    };

void main() {
  group('ArticleCategory.fromJson', () {
    test('필드를 그대로 매핑한다', () {
      final category = ArticleCategory.fromJson(_categoryJson());
      expect(category.name, '이유식/영양');
      expect(category.slug, 'nutrition');
    });
  });

  group('Article.fromJson', () {
    test('thumbnailUrl이 null이어도 처리한다', () {
      final article = Article.fromJson(_articleJson(thumbnailUrl: null));
      expect(article.thumbnailUrl, isNull);
      expect(article.title, '이유식 시작 시기와 순서 가이드');
      expect(article.category.slug, 'nutrition');
      expect(article.createdAt, DateTime.parse('2026-08-14T00:00:00.000Z'));
    });
  });

  group('ArticlePage.fromJson', () {
    test('hasMore를 page/totalPages로 계산한다', () {
      final page = ArticlePage.fromJson({
        'items': [_articleJson()],
        'page': 2,
        'totalPages': 2,
      });
      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
    });
  });
}
