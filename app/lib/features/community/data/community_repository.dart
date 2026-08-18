import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/comment.dart';
import '../domain/post.dart';
import '../domain/post_detail.dart';

class CommunityRepository {
  CommunityRepository(this._dio);

  final Dio _dio;

  Future<PostPage> fetchPosts({required int page, String? q}) async {
    final queryParameters = <String, dynamic>{'page': page};
    if (q != null && q.isNotEmpty) queryParameters['q'] = q;

    final response = await _dio.get(ApiEndpoints.posts, queryParameters: queryParameters);
    return PostPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostDetail> fetchPostDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.post(id));
    return PostDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PostDetail> createPost({
    required String title,
    required String content,
    String? category,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{'title': title, 'content': content};
    if (category != null && category.isNotEmpty) data['category'] = category;
    if (imageUrl != null) data['imageUrl'] = imageUrl;

    final response = await _dio.post(ApiEndpoints.posts, data: data);
    return fetchPostDetail((response.data as Map<String, dynamic>)['id'] as String);
  }

  Future<PostDetail> updatePost(
    String postId, {
    required String title,
    required String content,
    String? category,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{'title': title, 'content': content};
    if (category != null && category.isNotEmpty) data['category'] = category;
    if (imageUrl != null) data['imageUrl'] = imageUrl;

    await _dio.patch(ApiEndpoints.post(postId), data: data);
    return fetchPostDetail(postId);
  }

  Future<void> deletePost(String postId) async {
    await _dio.delete(ApiEndpoints.post(postId));
  }

  // XFile.readAsBytes()로 얻은 바이트를 그대로 받아, presentation 레이어가
  // image_picker 같은 플랫폼 패키지에 의존하지 않도록 한다.
  Future<String> uploadImage({required List<int> bytes, required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post(ApiEndpoints.uploads, data: formData);
    return (response.data as Map<String, dynamic>)['url'] as String;
  }

  Future<Comment> addComment(String postId, String content) async {
    final response = await _dio.post(
      ApiEndpoints.postComments(postId),
      data: {'content': content},
    );
    return Comment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteComment(String commentId) async {
    await _dio.delete(ApiEndpoints.comment(commentId));
  }

  Future<({bool liked, int likeCount})> toggleLike(String postId) async {
    final response = await _dio.post(ApiEndpoints.postLike(postId));
    final data = response.data as Map<String, dynamic>;
    return (liked: data['liked'] as bool, likeCount: data['likeCount'] as int);
  }
}
