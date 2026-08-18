import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/category.dart';
import '../domain/product.dart';
import '../domain/product_detail.dart';

class ProductsRepository {
  ProductsRepository(this._dio);

  final Dio _dio;

  Future<List<Category>> fetchCategories() async {
    final response = await _dio.get(ApiEndpoints.categories);
    return (response.data as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductPage> fetchProducts({
    required int page,
    String? categoryId,
    String? query,
    bool includeInactive = false,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'pageSize': includeInactive ? 50 : 20};
    if (categoryId != null) queryParameters['categoryId'] = categoryId;
    if (query != null && query.isNotEmpty) queryParameters['q'] = query;
    if (includeInactive) queryParameters['includeInactive'] = true;

    final response = await _dio.get(
      ApiEndpoints.products,
      queryParameters: queryParameters,
    );
    return ProductPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductDetail> fetchProductDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.product(id));
    return ProductDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> createReview(String productId, {required int rating, required String content}) async {
    await _dio.post(
      ApiEndpoints.productReviews(productId),
      data: {'rating': rating, 'content': content},
    );
  }

  Future<void> updateReview(String reviewId, {required int rating, required String content}) async {
    await _dio.patch(
      ApiEndpoints.review(reviewId),
      data: {'rating': rating, 'content': content},
    );
  }

  Future<void> deleteReview(String reviewId) async {
    await _dio.delete(ApiEndpoints.review(reviewId));
  }

  Future<ProductDetail> createProduct({
    required String categoryId,
    required String name,
    required String description,
    required int price,
    required int stock,
    required List<String> imageUrls,
  }) async {
    final response = await _dio.post(ApiEndpoints.products, data: {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrls': imageUrls,
    });
    return ProductDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProductDetail> updateProduct(
    String id, {
    String? categoryId,
    String? name,
    String? description,
    int? price,
    int? stock,
    List<String>? imageUrls,
    bool? isActive,
  }) async {
    final response = await _dio.patch(ApiEndpoints.product(id), data: {
      if (categoryId != null) 'categoryId': categoryId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (imageUrls != null) 'imageUrls': imageUrls,
      if (isActive != null) 'isActive': isActive,
    });
    return ProductDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> uploadImage({required List<int> bytes, required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post(ApiEndpoints.uploads, data: formData);
    return (response.data as Map<String, dynamic>)['url'] as String;
  }
}
