import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parenting_app/features/cart/data/cart_repository.dart';
import 'package:parenting_app/features/cart/domain/cart.dart';
import 'package:parenting_app/features/cart/presentation/cart_controller.dart';

import '../../../support/flush.dart';

class MockCartRepository extends Mock implements CartRepository {}

Cart _cartWith({int quantity = 1, int price = 10000}) {
  return Cart.fromJson({
    'items': [
      {
        'productId': 'p1',
        'quantity': quantity,
        'product': {'name': '기저귀', 'price': price, 'stock': 100, 'images': []},
      },
    ],
  });
}

DioException _stockError() {
  return DioException(
    requestOptions: RequestOptions(path: '/api/cart/items'),
    response: Response(
      requestOptions: RequestOptions(path: '/api/cart/items'),
      statusCode: 400,
      data: {'message': '재고가 부족합니다. (재고 3개)'},
    ),
  );
}

void main() {
  late MockCartRepository repository;

  setUp(() {
    repository = MockCartRepository();
  });

  test('생성 시 refresh가 호출되어 장바구니를 불러온다', () async {
    when(() => repository.fetchCart()).thenAnswer((_) async => _cartWith());

    final controller = CartController(repository);
    expect(controller.state, isA<AsyncLoading<Cart>>());

    await flushMicrotasks();
    expect(controller.state.value?.items, hasLength(1));
  });

  test('fetchCart가 실패하면 AsyncError 상태가 된다', () async {
    when(() => repository.fetchCart()).thenThrow(Exception('network down'));

    final controller = CartController(repository);
    await flushMicrotasks();

    expect(controller.state.hasError, isTrue);
  });

  group('addItem', () {
    test('성공하면 새 장바구니로 상태를 갱신하고 null을 반환한다', () async {
      when(() => repository.fetchCart()).thenAnswer((_) async => _cartWith(quantity: 0));
      when(() => repository.addItem(any(), any())).thenAnswer((_) async => _cartWith(quantity: 2));

      final controller = CartController(repository);
      await flushMicrotasks();

      final message = await controller.addItem('p1', quantity: 2);

      expect(message, isNull);
      expect(controller.state.value?.items.first.quantity, 2);
    });

    test('재고 초과 등 서버 오류 시 메시지를 반환하고 상태는 유지한다', () async {
      final initialCart = _cartWith(quantity: 1);
      when(() => repository.fetchCart()).thenAnswer((_) async => initialCart);
      when(() => repository.addItem(any(), any())).thenThrow(_stockError());

      final controller = CartController(repository);
      await flushMicrotasks();

      final message = await controller.addItem('p1', quantity: 10);

      expect(message, '재고가 부족합니다. (재고 3개)');
      expect(controller.state.value?.items.first.quantity, 1);
    });
  });

  group('updateItem', () {
    test('성공하면 갱신된 수량을 반영한다', () async {
      when(() => repository.fetchCart()).thenAnswer((_) async => _cartWith(quantity: 1));
      when(() => repository.updateItem(any(), any())).thenAnswer((_) async => _cartWith(quantity: 5));

      final controller = CartController(repository);
      await flushMicrotasks();

      final message = await controller.updateItem('p1', 5);

      expect(message, isNull);
      expect(controller.state.value?.items.first.quantity, 5);
    });
  });

  group('removeItem', () {
    test('성공하면 빈 장바구니를 반영한다', () async {
      when(() => repository.fetchCart()).thenAnswer((_) async => _cartWith());
      when(() => repository.removeItem(any())).thenAnswer((_) async => Cart.fromJson({'items': []}));

      final controller = CartController(repository);
      await flushMicrotasks();

      final message = await controller.removeItem('p1');

      expect(message, isNull);
      expect(controller.state.value?.isEmpty, isTrue);
    });
  });
}
