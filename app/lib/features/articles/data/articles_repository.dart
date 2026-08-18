import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/article.dart';
import '../domain/article_category.dart';
import '../domain/article_detail.dart';

class ArticlesRepository {
  ArticlesRepository(this._dio);

  final Dio _dio;

  Future<List<ArticleCategory>> fetchCategories() async {
    final response = await _dio.get(ApiEndpoints.articleCategories);
    return (response.data as List<dynamic>)
        .map((e) => ArticleCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ArticlePage> fetchArticles({
    required int page,
    String? categoryId,
    bool includeInactive = false,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'pageSize': includeInactive ? 50 : 20};
    if (categoryId != null) queryParameters['categoryId'] = categoryId;
    if (includeInactive) queryParameters['includeInactive'] = true;

    final response = await _dio.get(
      ApiEndpoints.articles,
      queryParameters: queryParameters,
    );
    return ArticlePage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ArticleDetail> fetchArticleDetail(String id, {bool includeInactive = false}) async {
    final response = await _dio.get(
      ApiEndpoints.article(id),
      queryParameters: includeInactive ? {'includeInactive': true} : null,
    );
    return ArticleDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ArticleDetail> createArticle({
    required String categoryId,
    required String title,
    required String content,
    String? thumbnailUrl,
  }) async {
    final response = await _dio.post(ApiEndpoints.articles, data: {
      'categoryId': categoryId,
      'title': title,
      'content': content,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    });
    return ArticleDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ArticleDetail> updateArticle(
    String id, {
    String? categoryId,
    String? title,
    String? content,
    String? thumbnailUrl,
    bool? isActive,
  }) async {
    final response = await _dio.patch(ApiEndpoints.article(id), data: {
      if (categoryId != null) 'categoryId': categoryId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (isActive != null) 'isActive': isActive,
    });
    return ArticleDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteArticle(String id) async {
    await _dio.delete(ApiEndpoints.article(id));
  }

  Future<String> uploadImage({required List<int> bytes, required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post(ApiEndpoints.uploads, data: formData);
    return (response.data as Map<String, dynamic>)['url'] as String;
  }
}
