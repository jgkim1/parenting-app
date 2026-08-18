import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parenting_app/features/products/data/products_repository.dart';
import 'package:parenting_app/features/products/domain/product.dart';
import 'package:parenting_app/features/products/presentation/products_controller.dart';

import '../../../support/flush.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

Product _product(String name) => Product.fromJson({
      'id': name,
      'name': name,
      'price': 1000,
      'stock': 10,
      'category': {'id': 'c1', 'name': '카테고리', 'slug': 'cat'},
      'images': [],
    });

ProductPage _page(List<String> names, {required int page, required int totalPages}) {
  return ProductPage(items: names.map(_product).toList(), page: page, totalPages: totalPages);
}

void main() {
  late MockProductsRepository repository;

  setUp(() {
    repository = MockProductsRepository();
  });

  test('생성 시 1페이지를 불러온다', () async {
    when(() => repository.fetchProducts(page: 1, categoryId: null, query: ''))
        .thenAnswer((_) async => _page(['a', 'b'], page: 1, totalPages: 2));

    final controller = ProductsListController(repository);
    expect(controller.state.isLoading, isTrue);

    await flushMicrotasks();

    expect(controller.state.items, hasLength(2));
    expect(controller.state.isLoading, isFalse);
    expect(controller.state.hasMore, isTrue);
  });

  test('loadInitial 실패 시 에러 메시지를 담고 목록은 비운다', () async {
    when(() => repository.fetchProducts(page: 1, categoryId: null, query: ''))
        .thenThrow(DioException(requestOptions: RequestOptions(path: '/api/products')));

    final controller = ProductsListController(repository);
    await flushMicrotasks();

    expect(controller.state.errorMessage, isNotNull);
    expect(controller.state.items, isEmpty);
  });

  test('loadMore는 다음 페이지를 이어붙이고, 마지막 페이지 이후에는 더 불러오지 않는다', () async {
    when(() => repository.fetchProducts(page: 1, categoryId: null, query: ''))
        .thenAnswer((_) async => _page(['a'], page: 1, totalPages: 2));
    when(() => repository.fetchProducts(page: 2, categoryId: null, query: ''))
        .thenAnswer((_) async => _page(['b'], page: 2, totalPages: 2));

    final controller = ProductsListController(repository);
    await flushMicrotasks();

    await controller.loadMore();
    expect(controller.state.items.map((p) => p.name), ['a', 'b']);
    expect(controller.state.hasMore, isFalse);

    await controller.loadMore();
    verifyNever(() => repository.fetchProducts(page: 3, categoryId: any(named: 'categoryId'), query: any(named: 'query')));
    expect(controller.state.items, hasLength(2));
  });

  test('setCategory는 1페이지부터 다시 불러온다', () async {
    when(() => repository.fetchProducts(page: 1, categoryId: null, query: ''))
        .thenAnswer((_) async => _page(['a'], page: 1, totalPages: 1));
    when(() => repository.fetchProducts(page: 1, categoryId: 'cat-1', query: ''))
        .thenAnswer((_) async => _page(['b'], page: 1, totalPages: 1));

    final controller = ProductsListController(repository);
    await flushMicrotasks();

    controller.setCategory('cat-1');
    await flushMicrotasks();

    expect(controller.state.categoryId, 'cat-1');
    expect(controller.state.items.single.name, 'b');
  });

  test('같은 카테고리를 다시 선택하면 재요청하지 않는다', () async {
    when(() => repository.fetchProducts(page: 1, categoryId: null, query: ''))
        .thenAnswer((_) async => _page(['a'], page: 1, totalPages: 1));

    final controller = ProductsListController(repository);
    await flushMicrotasks();

    controller.setCategory(null);
    await flushMicrotasks();

    verify(() => repository.fetchProducts(page: 1, categoryId: null, query: '')).called(1);
  });

  test('search는 검색어를 상태에 반영하고 1페이지부터 다시 불러온다', () async {
    when(() => repository.fetchProducts(page: 1, categoryId: null, query: ''))
        .thenAnswer((_) async => _page(['a'], page: 1, totalPages: 1));
    when(() => repository.fetchProducts(page: 1, categoryId: null, query: '유모차'))
        .thenAnswer((_) async => _page(['유모차'], page: 1, totalPages: 1));

    final controller = ProductsListController(repository);
    await flushMicrotasks();

    controller.search('유모차');
    await flushMicrotasks();

    expect(controller.state.query, '유모차');
    expect(controller.state.items.single.name, '유모차');
  });
}
