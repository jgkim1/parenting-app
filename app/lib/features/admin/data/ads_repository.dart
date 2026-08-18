import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/ad.dart';

class AdsRepository {
  AdsRepository(this._dio);

  final Dio _dio;

  Future<List<Ad>> fetchAds({AdPlacement? placement, bool includeInactive = false}) async {
    final response = await _dio.get(
      ApiEndpoints.ads,
      queryParameters: {
        if (placement != null) 'placement': placement.apiValue,
        if (includeInactive) 'includeInactive': true,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => Ad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Ad> createAd({
    required AdPlacement placement,
    required String title,
    required String imageUrl,
    String? linkUrl,
    int sortOrder = 0,
  }) async {
    final response = await _dio.post(ApiEndpoints.ads, data: {
      'placement': placement.apiValue,
      'title': title,
      'imageUrl': imageUrl,
      if (linkUrl != null) 'linkUrl': linkUrl,
      'sortOrder': sortOrder,
    });
    return Ad.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Ad> updateAd(
    String id, {
    AdPlacement? placement,
    String? title,
    String? imageUrl,
    String? linkUrl,
    int? sortOrder,
    bool? isActive,
  }) async {
    final response = await _dio.patch(ApiEndpoints.ad(id), data: {
      if (placement != null) 'placement': placement.apiValue,
      if (title != null) 'title': title,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (linkUrl != null) 'linkUrl': linkUrl,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (isActive != null) 'isActive': isActive,
    });
    return Ad.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAd(String id) async {
    await _dio.delete(ApiEndpoints.ad(id));
  }

  Future<String> uploadImage({required List<int> bytes, required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post(ApiEndpoints.uploads, data: formData);
    return (response.data as Map<String, dynamic>)['url'] as String;
  }
}
