// 소셜 로그인에 필요한 앱 키 모음.
//
// 값을 비워두면 해당 프로바이더의 로그인 버튼이 "설정이 필요합니다" 안내만 하고 앱은
// 정상적으로 동작한다(서버 쪽 GOOGLE_CLIENT_ID 미설정 시 503을 반환하는 것과 같은 패턴).
//
// - 구글: https://console.cloud.google.com 에서 OAuth 클라이언트 ID(웹 애플리케이션)를 발급받아
//   googleClientId에 채운다. 서버 .env의 GOOGLE_CLIENT_ID와 반드시 같은 값이어야 한다.
// - 카카오: https://developers.kakao.com 에서 앱을 등록한 뒤 네이티브 앱 키를
//   kakaoNativeAppKey에 채운다. (카카오 로그인은 Android/iOS 전용이며 Flutter Web SDK는
//   아직 로그인 자체를 지원하지 않는다.)
class SocialLoginConfig {
  SocialLoginConfig._();

  static const String googleClientId = '';
  static const String kakaoNativeAppKey = '';

  static bool get isGoogleConfigured => googleClientId.isNotEmpty;
  static bool get isKakaoConfigured => kakaoNativeAppKey.isNotEmpty;
}
