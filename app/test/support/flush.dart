// StateNotifier 생성자나 메서드 안에서 시작된 비동기 작업(리포지토리 호출 등)이
// state에 반영될 때까지 이벤트 루프를 두 바퀴 돌려 마이크로태스크를 흘려보낸다.
// Flutter 위젯 pumping 없이 순수 Dart 단위 테스트에서 비동기 상태 전이를 기다릴 때 쓴다.
Future<void> flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
