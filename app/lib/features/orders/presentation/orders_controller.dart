import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart' show dioProvider;
import '../data/orders_repository.dart';
import '../domain/order.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(dioProvider));
});

final orderDetailProvider = FutureProvider.family.autoDispose<Order, String>((ref, id) {
  return ref.watch(ordersRepositoryProvider).fetchOrderDetail(id);
});

class OrdersListState {
  const OrdersListState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<Order> items;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get hasMore => page < totalPages;

  OrdersListState copyWith({
    List<Order>? items,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrdersListState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OrdersListController extends StateNotifier<OrdersListState> {
  OrdersListController(this._repository) : super(const OrdersListState()) {
    loadInitial();
  }

  final OrdersRepository _repository;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.fetchOrders(page: 1);
      state = state.copyWith(
        items: result.items,
        page: result.page,
        totalPages: result.totalPages,
        isLoading: false,
      );
    } on DioException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '주문 내역을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.fetchOrders(page: state.page + 1);
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
}

final ordersListControllerProvider =
    StateNotifierProvider.autoDispose<OrdersListController, OrdersListState>((ref) {
  return OrdersListController(ref.watch(ordersRepositoryProvider));
});
