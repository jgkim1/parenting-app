import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart' show dioProvider;
import '../data/children_repository.dart';
import '../domain/child.dart';

final childrenRepositoryProvider = Provider<ChildrenRepository>((ref) {
  return ChildrenRepository(ref.watch(dioProvider));
});

class ChildrenController extends StateNotifier<AsyncValue<List<Child>>> {
  ChildrenController(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  final ChildrenRepository _repository;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchChildren());
  }
}

final childrenControllerProvider =
    StateNotifierProvider<ChildrenController, AsyncValue<List<Child>>>((ref) {
  return ChildrenController(ref.watch(childrenRepositoryProvider));
});
