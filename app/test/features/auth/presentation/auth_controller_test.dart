import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parenting_app/features/auth/data/auth_repository.dart';
import 'package:parenting_app/features/auth/data/social/google_auth_service.dart';
import 'package:parenting_app/features/auth/data/social/kakao_auth_service.dart';
import 'package:parenting_app/features/auth/domain/user.dart';
import 'package:parenting_app/features/auth/presentation/auth_controller.dart';

import '../../../support/flush.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockKakaoAuthService extends Mock implements KakaoAuthService {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

const _user = AppUser(id: 'u1', email: 'test@example.com', nickname: '테스터', role: 'CUSTOMER');

DioException _errorWithMessage(String message) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/auth/login'),
    response: Response(
      requestOptions: RequestOptions(path: '/api/auth/login'),
      statusCode: 401,
      data: {'message': message},
    ),
  );
}

void main() {
  late MockAuthRepository repository;
  late MockKakaoAuthService kakaoAuthService;
  late MockGoogleAuthService googleAuthService;

  AuthController buildController() =>
      AuthController(repository, kakaoAuthService, googleAuthService);

  setUp(() {
    repository = MockAuthRepository();
    kakaoAuthService = MockKakaoAuthService();
    googleAuthService = MockGoogleAuthService();
  });

  group('세션 복구', () {
    test('저장된 세션이 있으면 AuthAuthenticated로 시작한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => _user);

      final controller = buildController();
      expect(controller.state, isA<AuthLoading>());

      await flushMicrotasks();
      expect(controller.state, isA<AuthAuthenticated>());
      expect((controller.state as AuthAuthenticated).user.nickname, '테스터');
    });

    test('저장된 세션이 없으면 AuthUnauthenticated로 시작한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);

      final controller = buildController();
      await flushMicrotasks();

      expect(controller.state, isA<AuthUnauthenticated>());
    });
  });

  group('로그인', () {
    test('성공하면 AuthAuthenticated로 전이한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);
      when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => _user);

      final controller = buildController();
      await flushMicrotasks();

      await controller.login(email: 'test@example.com', password: 'password123');

      expect(controller.state, isA<AuthAuthenticated>());
    });

    test('실패하면 서버 에러 메시지를 담아 AuthUnauthenticated로 전이한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);
      when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(_errorWithMessage('이메일 또는 비밀번호가 올바르지 않습니다.'));

      final controller = buildController();
      await flushMicrotasks();

      await controller.login(email: 'test@example.com', password: 'wrong');

      final state = controller.state as AuthUnauthenticated;
      expect(state.errorMessage, '이메일 또는 비밀번호가 올바르지 않습니다.');
    });

    test('서버가 message 없이 실패하면 기본 안내 문구를 쓴다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);
      when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/auth/login')),
      );

      final controller = buildController();
      await flushMicrotasks();

      await controller.login(email: 'test@example.com', password: 'wrong');

      final state = controller.state as AuthUnauthenticated;
      expect(state.errorMessage, '요청을 처리하지 못했습니다. 잠시 후 다시 시도해주세요.');
    });
  });

  group('회원가입', () {
    test('성공하면 AuthAuthenticated로 전이한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);
      when(() => repository.signup(
            email: any(named: 'email'),
            password: any(named: 'password'),
            nickname: any(named: 'nickname'),
          )).thenAnswer((_) async => _user);

      final controller = buildController();
      await flushMicrotasks();

      await controller.signup(email: 'test@example.com', password: 'password123', nickname: '테스터');

      expect(controller.state, isA<AuthAuthenticated>());
    });
  });

  group('카카오 로그인', () {
    test('성공하면 AuthAuthenticated로 전이한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);
      when(() => kakaoAuthService.signIn()).thenAnswer((_) async => 'kakao-access-token');
      when(() => repository.loginWithKakao('kakao-access-token')).thenAnswer((_) async => _user);

      final controller = buildController();
      await flushMicrotasks();

      await controller.loginWithKakao();

      expect(controller.state, isA<AuthAuthenticated>());
    });

    test('사용자가 취소하면 에러 없이 AuthUnauthenticated로 전이한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);
      when(() => kakaoAuthService.signIn()).thenThrow(KakaoLoginCancelledException());

      final controller = buildController();
      await flushMicrotasks();

      await controller.loginWithKakao();

      final state = controller.state as AuthUnauthenticated;
      expect(state.errorMessage, isNull);
    });

    test('플랫폼 미지원이면 안내 메시지를 담아 AuthUnauthenticated로 전이한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);
      when(() => kakaoAuthService.signIn()).thenThrow(KakaoLoginUnsupportedException());

      final controller = buildController();
      await flushMicrotasks();

      await controller.loginWithKakao();

      final state = controller.state as AuthUnauthenticated;
      expect(state.errorMessage, isNotNull);
    });
  });

  group('구글 로그인', () {
    test('성공하면 AuthAuthenticated로 전이한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);
      when(() => googleAuthService.signIn()).thenAnswer((_) async => 'google-id-token');
      when(() => repository.loginWithGoogle('google-id-token')).thenAnswer((_) async => _user);

      final controller = buildController();
      await flushMicrotasks();

      await controller.loginWithGoogle();

      expect(controller.state, isA<AuthAuthenticated>());
    });

    test('서버가 이메일 충돌로 거부하면 서버 메시지를 담아 AuthUnauthenticated로 전이한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);
      when(() => googleAuthService.signIn()).thenAnswer((_) async => 'google-id-token');
      when(() => repository.loginWithGoogle('google-id-token')).thenThrow(
        _errorWithMessage('이미 이메일/비밀번호로 가입된 이메일입니다. 해당 방식으로 로그인해주세요.'),
      );

      final controller = buildController();
      await flushMicrotasks();

      await controller.loginWithGoogle();

      final state = controller.state as AuthUnauthenticated;
      expect(state.errorMessage, '이미 이메일/비밀번호로 가입된 이메일입니다. 해당 방식으로 로그인해주세요.');
    });
  });

  group('로그아웃', () {
    test('AuthUnauthenticated로 전이한다', () async {
      when(() => repository.tryRestoreSession()).thenAnswer((_) async => _user);
      when(() => repository.logout()).thenAnswer((_) async {});

      final controller = buildController();
      await flushMicrotasks();
      expect(controller.state, isA<AuthAuthenticated>());

      await controller.logout();

      expect(controller.state, isA<AuthUnauthenticated>());
      verify(() => repository.logout()).called(1);
    });
  });
}
