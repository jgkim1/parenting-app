import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/cart/domain/cart.dart';

Map<String, dynamic> _cartItemJson({
  int price = 10000,
  int quantity = 2,
  List<dynamic>? images,
}) =>
    {
      'productId': 'p1',
      'quantity': quantity,
      'product': {
        'name': '기저귀',
        'price': price,
        'stock': 100,
        'images': images ?? [],
      },
    };

void main() {
  group('CartItem.fromJson', () {
    test('subtotal은 단가*수량이다', () {
      final item = CartItem.fromJson(_cartItemJson(price: 10000, quantity: 3));
      expect(item.unitPrice, 10000);
      expect(item.quantity, 3);
      expect(item.subtotal, 30000);
    });

    test('상품 이미지가 없으면 썸네일은 null이다', () {
      final item = CartItem.fromJson(_cartItemJson(images: []));
      expect(item.thumbnailUrl, isNull);
    });
  });

  group('Cart', () {
    test('totalAmount/totalQuantity는 아이템들의 합이다', () {
      final cart = Cart.fromJson({
        'items': [
          _cartItemJson(price: 10000, quantity: 2), // 20000
          _cartItemJson(price: 5000, quantity: 1), // 5000
        ],
      });

      expect(cart.totalAmount, 25000);
      expect(cart.totalQuantity, 3);
      expect(cart.isEmpty, isFalse);
    });

    test('아이템이 없으면 isEmpty가 true이고 합계는 0이다', () {
      final cart = Cart.fromJson({'items': []});
      expect(cart.isEmpty, isTrue);
      expect(cart.totalAmount, 0);
      expect(cart.totalQuantity, 0);
    });
  });
}
