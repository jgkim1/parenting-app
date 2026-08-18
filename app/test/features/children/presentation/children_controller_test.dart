import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parenting_app/features/children/data/children_repository.dart';
import 'package:parenting_app/features/children/domain/child.dart';
import 'package:parenting_app/features/children/presentation/children_controller.dart';

import '../../../support/flush.dart';

class MockChildrenRepository extends Mock implements ChildrenRepository {}

Child _child(String nickname) =>
    Child(id: nickname, nickname: nickname, gender: null, birthDate: DateTime(2024, 1, 1));

void main() {
  late MockChildrenRepository repository;

  setUp(() {
    repository = MockChildrenRepository();
  });

  test('생성 시 자녀 목록을 불러온다', () async {
    when(() => repository.fetchChildren()).thenAnswer((_) async => [_child('첫째')]);

    final controller = ChildrenController(repository);
    expect(controller.state, isA<AsyncLoading<List<Child>>>());

    await flushMicrotasks();

    expect(controller.state.value, hasLength(1));
    expect(controller.state.value!.single.nickname, '첫째');
  });

  test('refresh 실패 시 AsyncError가 된다', () async {
    when(() => repository.fetchChildren()).thenThrow(Exception('network error'));

    final controller = ChildrenController(repository);
    await flushMicrotasks();

    expect(controller.state.hasError, isTrue);
  });

  test('refresh를 다시 호출하면 최신 목록으로 갱신된다', () async {
    var callCount = 0;
    when(() => repository.fetchChildren()).thenAnswer((_) async {
      callCount += 1;
      return callCount == 1 ? [_child('첫째')] : [_child('첫째'), _child('둘째')];
    });

    final controller = ChildrenController(repository);
    await flushMicrotasks();
    expect(controller.state.value, hasLength(1));

    await controller.refresh();
    expect(controller.state.value, hasLength(2));
  });
}
