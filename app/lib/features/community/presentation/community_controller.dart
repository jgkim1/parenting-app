import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart' show dioProvider;
import '../data/community_repository.dart';
import '../domain/post.dart';
import '../domain/post_detail.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(dioProvider));
});

class PostsListState {
  const PostsListState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.query = '',
    this.errorMessage,
  });

  final List<Post> items;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String query;
  final String? errorMessage;

  bool get hasMore => page < totalPages;

  PostsListState copyWith({
    List<Post>? items,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? query,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PostsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      query: query ?? this.query,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PostsListController extends StateNotifier<PostsListState> {
  PostsListController(this._repository) : super(const PostsListState()) {
    loadInitial();
  }

  final CommunityRepository _repository;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.fetchPosts(page: 1, q: state.query);
      state = state.copyWith(
        items: result.items,
        page: result.page,
        totalPages: result.totalPages,
        isLoading: false,
      );
    } on DioException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '게시글을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.fetchPosts(page: state.page + 1, q: state.query);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } on DioException {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void search(String query) {
    if (state.query == query) return;
    state = state.copyWith(query: query);
    loadInitial();
  }
}

final postsListControllerProvider =
    StateNotifierProvider.autoDispose<PostsListController, PostsListState>((ref) {
  return PostsListController(ref.watch(communityRepositoryProvider));
});

class PostDetailController extends StateNotifier<AsyncValue<PostDetail>> {
  PostDetailController(this._repository, this._postId) : super(const AsyncValue.loading()) {
    refresh();
  }

  final CommunityRepository _repository;
  final String _postId;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchPostDetail(_postId));
  }

  Future<String?> addComment(String content) async {
    try {
      final comment = await _repository.addComment(_postId, content);
      final current = state.value;
      if (current != null) {
        state = AsyncValue.data(current.copyWith(comments: [...current.comments, comment]));
      }
      return null;
    } on DioException catch (e) {
      return _extractMessage(e);
    }
  }

  Future<String?> deleteComment(String commentId) async {
    try {
      await _repository.deleteComment(commentId);
      final current = state.value;
      if (current != null) {
        state = AsyncValue.data(
          current.copyWith(
            comments: current.comments.where((c) => c.id != commentId).toList(),
          ),
        );
      }
      return null;
    } on DioException catch (e) {
      return _extractMessage(e);
    }
  }

  Future<void> toggleLike() async {
    final current = state.value;
    if (current == null) return;
    try {
      final result = await _repository.toggleLike(_postId);
      state = AsyncValue.data(
        current.copyWith(likedByMe: result.liked, likeCount: result.likeCount),
      );
    } on DioException {
      // 좋아요 토글 실패는 조용히 무시하고 이전 상태를 유지한다.
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return '요청을 처리하지 못했습니다. 잠시 후 다시 시도해주세요.';
  }
}

final postDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<PostDetailController, AsyncValue<PostDetail>, String>((ref, postId) {
  return PostDetailController(ref.watch(communityRepositoryProvider), postId);
});
