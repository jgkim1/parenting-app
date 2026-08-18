import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/dio_client.dart';
import '../data/auth_repository.dart';
import '../data/social/google_auth_service.dart';
import '../data/social/kakao_auth_service.dart';
import '../domain/user.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => const TokenStorage());

final dioProvider = Provider<Dio>((ref) => buildDio(ref.watch(tokenStorageProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});

final kakaoAuthServiceProvider = Provider<KakaoAuthService>((ref) => KakaoAuthService());

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) => GoogleAuthService());

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AppUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.errorMessage});
  final String? errorMessage;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._kakaoAuthService, this._googleAuthService)
      : super(const AuthLoading()) {
    _restore();
  }

  final AuthRepository _repository;
  final KakaoAuthService _kakaoAuthService;
  final GoogleAuthService _googleAuthService;

  Future<void> _restore() async {
    final user = await _repository.tryRestoreSession();
    state = user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthAuthenticated(user);
    } on DioException catch (e) {
      state = AuthUnauthenticated(errorMessage: _extractMessage(e));
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.signup(email: email, password: password, nickname: nickname);
      state = AuthAuthenticated(user);
    } on DioException catch (e) {
      state = AuthUnauthenticated(errorMessage: _extractMessage(e));
    }
  }

  Future<void> loginWithKakao() async {
    state = const AuthLoading();
    try {
      final accessToken = await _kakaoAuthService.signIn();
      final user = await _repository.loginWithKakao(accessToken);
      state = AuthAuthenticated(user);
    } on KakaoLoginCancelledException {
      state = const AuthUnauthenticated();
    } on KakaoLoginUnsupportedException {
      state = const AuthUnauthenticated(
        errorMessage: '카카오 로그인은 모바일 앱에서만 이용할 수 있어요. (설정 필요)',
      );
    } on DioException catch (e) {
      state = AuthUnauthenticated(errorMessage: _extractMessage(e));
    }
  }

  Future<void> loginWithGoogle() async {
    state = const AuthLoading();
    try {
      final idToken = await _googleAuthService.signIn();
      final user = await _repository.loginWithGoogle(idToken);
      state = AuthAuthenticated(user);
    } on GoogleLoginCancelledException {
      state = const AuthUnauthenticated();
    } on GoogleLoginUnsupportedException {
      state = const AuthUnauthenticated(
        errorMessage: '이 플랫폼에서는 Google 로그인을 아직 지원하지 않아요. (설정 필요)',
      );
    } on DioException catch (e) {
      state = AuthUnauthenticated(errorMessage: _extractMessage(e));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return '요청을 처리하지 못했습니다. 잠시 후 다시 시도해주세요.';
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(kakaoAuthServiceProvider),
    ref.watch(googleAuthServiceProvider),
  );
});
