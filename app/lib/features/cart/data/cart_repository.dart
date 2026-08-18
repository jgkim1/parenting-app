import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/cart.dart';

class CartRepository {
  CartRepository(this._dio);

  final Dio _dio;

  Future<Cart> fetchCart() async {
    final response = await _dio.get(ApiEndpoints.cart);
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> addItem(String productId, int quantity) async {
    final response = await _dio.post(
      ApiEndpoints.cartItems,
      data: {'productId': productId, 'quantity': quantity},
    );
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> updateItem(String productId, int quantity) async {
    final response = await _dio.patch(
      ApiEndpoints.cartItem(productId),
      data: {'quantity': quantity},
    );
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Cart> removeItem(String productId) async {
    final response = await _dio.delete(ApiEndpoints.cartItem(productId));
    return Cart.fromJson(response.data as Map<String, dynamic>);
  }
}
