import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/order.dart';

class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;

  Future<OrderPage> fetchOrders({required int page}) async {
    final response = await _dio.get(ApiEndpoints.orders, queryParameters: {'page': page});
    return OrderPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Order> fetchOrderDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.order(id));
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Order> createOrder(String shippingAddr) async {
    final response = await _dio.post(
      ApiEndpoints.orders,
      data: {'shippingAddr': shippingAddr},
    );
    return Order.fromJson(response.data as Map<String, dynamic>);
  }
}
