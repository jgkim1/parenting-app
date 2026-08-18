import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/child.dart';

class ChildrenRepository {
  ChildrenRepository(this._dio);

  final Dio _dio;

  Future<List<Child>> fetchChildren() async {
    final response = await _dio.get(ApiEndpoints.children);
    return (response.data as List<dynamic>)
        .map((e) => Child.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createChild({
    required String nickname,
    required ChildGender? gender,
    required DateTime birthDate,
  }) async {
    await _dio.post(
      ApiEndpoints.children,
      data: {
        'nickname': nickname,
        if (gender != null) 'gender': gender.apiValue,
        'birthDate': birthDate.toIso8601String(),
      },
    );
  }

  Future<void> updateChild(
    String id, {
    required String nickname,
    required ChildGender? gender,
    required DateTime birthDate,
  }) async {
    await _dio.patch(
      ApiEndpoints.child(id),
      data: {
        'nickname': nickname,
        if (gender != null) 'gender': gender.apiValue,
        'birthDate': birthDate.toIso8601String(),
      },
    );
  }

  Future<void> deleteChild(String id) async {
    await _dio.delete(ApiEndpoints.child(id));
  }
}
