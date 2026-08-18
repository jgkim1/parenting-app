import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../../../../core/config/social_login_config.dart';

class KakaoLoginCancelledException implements Exception {}

class KakaoLoginUnsupportedException implements Exception {}

class KakaoAuthService {
  // 카카오톡 앱이 설치되어 있으면 카카오톡으로, 아니면 카카오계정(웹뷰)으로 로그인한 뒤
  // 서버에 그대로 전달할 사용자 액세스 토큰을 반환한다.
  // 카카오 Flutter SDK는 아직 웹 플랫폼에서 로그인을 지원하지 않는다.
  Future<String> signIn() async {
    if (kIsWeb || !SocialLoginConfig.isKakaoConfigured) {
      throw KakaoLoginUnsupportedException();
    }

    try {
      if (await isKakaoTalkInstalled()) {
        try {
          final token = await UserApi.instance.loginWithKakaoTalk();
          return token.accessToken;
        } catch (_) {
          // 카카오톡 로그인에 실패하면 카카오계정 로그인으로 대체 시도한다.
        }
      }
      final token = await UserApi.instance.loginWithKakaoAccount();
      return token.accessToken;
    } on KakaoAuthException catch (e) {
      if (e.error == AuthErrorCause.accessDenied) {
        throw KakaoLoginCancelledException();
      }
      rethrow;
    }
  }
}
