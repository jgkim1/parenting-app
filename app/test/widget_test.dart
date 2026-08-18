import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:parenting_app/app.dart';
import 'package:parenting_app/features/auth/data/auth_repository.dart';
import 'package:parenting_app/features/auth/presentation/auth_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('세션이 없으면 로그인 화면이 기본 라우트로 표시된다', (WidgetTester tester) async {
    // 실제 네트워크/시크릿 스토리지를 타지 않도록 세션 복구가 곧바로 실패하는 목으로 대체한다.
    final repository = MockAuthRepository();
    when(() => repository.tryRestoreSession()).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsWidgets);
  });
}
