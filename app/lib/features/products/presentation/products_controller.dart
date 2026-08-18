import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart' show dioProvider;
import '../data/products_repository.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import '../domain/product_detail.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(dioProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(productsRepositoryProvider).fetchCategories();
});

final productDetailProvider =
    FutureProvider.family.autoDispose<ProductDetail, String>((ref, id) {
  return ref.watch(productsRepositoryProvider).fetchProductDetail(id);
});

class ProductsListState {
  const ProductsListState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.categoryId,
    this.query = '',
    this.errorMessage,
  });

  final List<Product> items;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? categoryId;
  final String query;
  final String? errorMessage;

  bool get hasMore => page < totalPages;

  ProductsListState copyWith({
    List<Product>? items,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? categoryId,
    bool clearCategoryId = false,
    String? query,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      query: query ?? this.query,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProductsListController extends StateNotifier<ProductsListState> {
  ProductsListController(this._repository) : super(const ProductsListState()) {
    loadInitial();
  }

  final ProductsRepository _repository;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.fetchProducts(
        page: 1,
        categoryId: state.categoryId,
        query: state.query,
      );
      state = state.copyWith(
        items: result.items,
        page: result.page,
        totalPages: result.totalPages,
        isLoading: false,
      );
    } on DioException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '상품 목록을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.fetchProducts(
        page: state.page + 1,
        categoryId: state.categoryId,
        query: state.query,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } on DioException {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setCategory(String? categoryId) {
    if (state.categoryId == categoryId) return;
    state = state.copyWith(categoryId: categoryId, clearCategoryId: categoryId == null);
    loadInitial();
  }

  void search(String query) {
    if (state.query == query) return;
    state = state.copyWith(query: query);
    loadInitial();
  }
}

final productsListControllerProvider =
    StateNotifierProvider.autoDispose<ProductsListController, ProductsListState>((ref) {
  return ProductsListController(ref.watch(productsRepositoryProvider));
});
