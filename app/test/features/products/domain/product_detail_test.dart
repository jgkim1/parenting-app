import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/products/domain/product_detail.dart';

Map<String, dynamic> _detailJson({List<dynamic>? reviews}) => {
      'id': 'p1',
      'name': '휴대용 접이식 유모차',
      'description': '가벼운 유모차입니다.',
      'price': 189000,
      'stock': 23,
      'category': {'id': 'c1', 'name': '안전/외출용품', 'slug': 'safety-outdoor'},
      'seller': {'id': 's1', 'nickname': '육아용품 스토어'},
      'images': [
        {'url': 'https://example.com/a.png'},
      ],
      'reviews': reviews ?? [],
      'reviewStats': {'average': 0, 'count': 0},
    };

void main() {
  group('ProductReview.fromJson', () {
    test('user.id/nickname을 authorId/authorNickname으로 매핑한다', () {
      final review = ProductReview.fromJson({
        'id': 'r1',
        'rating': 4,
        'content': '좋아요',
        'user': {'id': 'u1', 'nickname': '테스터'},
      });

      expect(review.rating, 4);
      expect(review.content, '좋아요');
      expect(review.authorId, 'u1');
      expect(review.authorNickname, '테스터');
    });
  });

  group('ReviewStats.fromJson', () {
    test('정수/실수 평균값을 모두 double로 변환한다', () {
      expect(ReviewStats.fromJson({'average': 0, 'count': 0}).average, 0.0);
      expect(ReviewStats.fromJson({'average': 3.5, 'count': 2}).average, 3.5);
    });
  });

  group('ProductDetail.fromJson', () {
    test('중첩된 category/seller/images/reviewStats를 모두 매핑한다', () {
      final detail = ProductDetail.fromJson(_detailJson(reviews: [
        {
          'id': 'r1',
          'rating': 5,
          'content': '최고예요',
          'user': {'id': 'u1', 'nickname': '테스터'},
        },
      ]));

      expect(detail.name, '휴대용 접이식 유모차');
      expect(detail.category.name, '안전/외출용품');
      expect(detail.sellerNickname, '육아용품 스토어');
      expect(detail.imageUrls, ['https://example.com/a.png']);
      expect(detail.reviews, hasLength(1));
      expect(detail.reviews.first.authorNickname, '테스터');
    });

    test('reviews 키가 없어도 빈 리스트로 처리한다', () {
      final json = _detailJson()..remove('reviews');
      final detail = ProductDetail.fromJson(json);
      expect(detail.reviews, isEmpty);
    });
  });
}
