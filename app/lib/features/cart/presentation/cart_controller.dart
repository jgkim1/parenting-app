import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart' show dioProvider;
import '../data/cart_repository.dart';
import '../domain/cart.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(dioProvider));
});

class CartController extends StateNotifier<AsyncValue<Cart>> {
  CartController(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  final CartRepository _repository;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchCart());
  }

  Future<String?> addItem(String productId, {int quantity = 1}) async {
    try {
      final cart = await _repository.addItem(productId, quantity);
      state = AsyncValue.data(cart);
      return null;
    } on DioException catch (e) {
      return _extractMessage(e);
    }
  }

  Future<String?> updateItem(String productId, int quantity) async {
    try {
      final cart = await _repository.updateItem(productId, quantity);
      state = AsyncValue.data(cart);
      return null;
    } on DioException catch (e) {
      return _extractMessage(e);
    }
  }

  Future<String?> removeItem(String productId) async {
    try {
      final cart = await _repository.removeItem(productId);
      state = AsyncValue.data(cart);
      return null;
    } on DioException catch (e) {
      return _extractMessage(e);
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return '요청을 처리하지 못했습니다. 잠시 후 다시 시도해주세요.';
  }
}

final cartControllerProvider = StateNotifierProvider<CartController, AsyncValue<Cart>>((ref) {
  return CartController(ref.watch(cartRepositoryProvider));
});
