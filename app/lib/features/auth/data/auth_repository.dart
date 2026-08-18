import 'package:dio/dio.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/user.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AppUser> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _dio.post(ApiEndpoints.signup, data: {
      'email': email,
      'password': password,
      'nickname': nickname,
    });
    return _saveTokensAndReturnUser(response.data as Map<String, dynamic>);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    return _saveTokensAndReturnUser(response.data as Map<String, dynamic>);
  }

  // 카카오/구글 SDK에서 이미 발급받은 토큰을 서버에 전달해 검증받는다.
  // 서버가 신규 사용자면 계정을 만들고, 기존 소셜 계정이면 그대로 로그인시킨다.
  Future<AppUser> loginWithKakao(String accessToken) async {
    final response = await _dio.post(ApiEndpoints.kakaoLogin, data: {
      'accessToken': accessToken,
    });
    return _saveTokensAndReturnUser(response.data as Map<String, dynamic>);
  }

  Future<AppUser> loginWithGoogle(String idToken) async {
    final response = await _dio.post(ApiEndpoints.googleLogin, data: {
      'idToken': idToken,
    });
    return _saveTokensAndReturnUser(response.data as Map<String, dynamic>);
  }

  // 앱 시작 시 저장된 토큰으로 세션 복구를 시도한다. 토큰이 없거나 만료됐으면 null.
  Future<AppUser?> tryRestoreSession() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null) return null;

    try {
      final response = await _dio.get(ApiEndpoints.me);
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _dio.post(ApiEndpoints.logout, data: {'refreshToken': refreshToken});
      } on DioException {
        // 서버 로그아웃이 실패해도 로컬 토큰은 정리한다.
      }
    }
    await _tokenStorage.clear();
  }

  Future<AppUser> _saveTokensAndReturnUser(Map<String, dynamic> data) async {
    await _tokenStorage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
