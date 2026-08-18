import 'package:dio/dio.dart';
import '../auth/token_storage.dart';
import 'api_endpoints.dart';

// 모든 API 호출이 거치는 dio 인스턴스. 요청마다 액세스 토큰을 첨부하고,
// 401 응답을 받으면 리프레시 토큰으로 한 번 재발급을 시도한 뒤 원래 요청을 재시도한다.
Dio buildDio(TokenStorage tokenStorage) {
  final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await tokenStorage.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isRefreshCall = error.requestOptions.path == ApiEndpoints.refresh;

        if (!isUnauthorized || isRefreshCall) {
          return handler.next(error);
        }

        final refreshToken = await tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          await tokenStorage.clear();
          return handler.next(error);
        }

        try {
          // 인터셉터 재귀 호출을 피하기 위해 별도의 dio 인스턴스로 리프레시를 요청한다.
          final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
          final response = await refreshDio.post(
            ApiEndpoints.refresh,
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = response.data['accessToken'] as String;
          final newRefreshToken = response.data['refreshToken'] as String;
          await tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          await tokenStorage.clear();
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
}
