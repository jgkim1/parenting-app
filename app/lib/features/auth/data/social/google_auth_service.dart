import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/config/social_login_config.dart';

class GoogleLoginCancelledException implements Exception {}

class GoogleLoginUnsupportedException implements Exception {}

class GoogleAuthService {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: SocialLoginConfig.googleClientId,
    );
    _initialized = true;
  }

  // 서버 검증에 필요한 ID 토큰(JWT)을 반환한다.
  // 웹은 구글 SDK가 자체 렌더링 버튼으로만 로그인을 지원해 앱이 직접 로그인 창을 띄울 수 없다.
  Future<String> signIn() async {
    if (!SocialLoginConfig.isGoogleConfigured) {
      throw GoogleLoginUnsupportedException();
    }
    if (kIsWeb || !GoogleSignIn.instance.supportsAuthenticate()) {
      throw GoogleLoginUnsupportedException();
    }

    await _ensureInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw GoogleLoginUnsupportedException();
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleLoginCancelledException();
      }
      rethrow;
    }
  }
}
