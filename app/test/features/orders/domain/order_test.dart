import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/orders/domain/order.dart';

Map<String, dynamic> _orderItemJson({int price = 10000, int quantity = 2}) => {
      'productId': 'p1',
      'quantity': quantity,
      'priceAtOrder': price,
      'product': {'name': '유모차', 'images': []},
    };

Map<String, dynamic> _orderJson({String status = 'PENDING_PAYMENT', List<dynamic>? items}) => {
      'id': 'o1',
      'status': status,
      'totalAmount': 20000,
      'shippingAddr': '서울시 강남구',
      'createdAt': '2026-08-14T00:00:00.000Z',
      'items': items ?? [_orderItemJson()],
    };

void main() {
  group('OrderItem.fromJson', () {
    test('subtotal은 주문 시점 가격*수량이다', () {
      final item = OrderItem.fromJson(_orderItemJson(price: 10000, quantity: 3));
      expect(item.subtotal, 30000);
    });
  });

  group('Order.fromJson', () {
    test('items를 포함한 필드를 매핑한다', () {
      final order = Order.fromJson(_orderJson());
      expect(order.status, 'PENDING_PAYMENT');
      expect(order.totalAmount, 20000);
      expect(order.items, hasLength(1));
    });
  });

  group('OrderPage.fromJson', () {
    test('hasMore를 계산한다', () {
      final page = OrderPage.fromJson({'items': [_orderJson()], 'page': 1, 'totalPages': 2});
      expect(page.hasMore, isTrue);
    });
  });

  group('orderStatusLabel', () {
    test('알려진 상태는 한글 라벨로 변환한다', () {
      expect(orderStatusLabel('PENDING_PAYMENT'), '결제 대기');
      expect(orderStatusLabel('PAID'), '결제 완료');
      expect(orderStatusLabel('PREPARING'), '상품 준비중');
      expect(orderStatusLabel('SHIPPED'), '배송중');
      expect(orderStatusLabel('DELIVERED'), '배송 완료');
      expect(orderStatusLabel('CANCELLED'), '주문 취소');
    });

    test('알 수 없는 상태는 원본 문자열을 그대로 반환한다', () {
      expect(orderStatusLabel('UNKNOWN_STATUS'), 'UNKNOWN_STATUS');
    });
  });
}
