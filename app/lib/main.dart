import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'app.dart';
import 'core/config/social_login_config.dart';

void main() {
  // 카카오 앱 키가 설정되지 않았으면 SDK 초기화 자체를 생략한다(초기화 없이 호출하면 에러).
  if (SocialLoginConfig.isKakaoConfigured) {
    KakaoSdk.init(nativeAppKey: SocialLoginConfig.kakaoNativeAppKey);
  }
  runApp(const ProviderScope(child: App()));
}
