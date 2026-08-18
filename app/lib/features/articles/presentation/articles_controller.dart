import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart' show dioProvider;
import '../data/articles_repository.dart';
import '../domain/article.dart';
import '../domain/article_category.dart';
import '../domain/article_detail.dart';

final articlesRepositoryProvider = Provider<ArticlesRepository>((ref) {
  return ArticlesRepository(ref.watch(dioProvider));
});

final articleCategoriesProvider = FutureProvider<List<ArticleCategory>>((ref) {
  return ref.watch(articlesRepositoryProvider).fetchCategories();
});

final articleDetailProvider =
    FutureProvider.family.autoDispose<ArticleDetail, String>((ref, id) {
  return ref.watch(articlesRepositoryProvider).fetchArticleDetail(id);
});

class ArticlesListState {
  const ArticlesListState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.categoryId,
    this.errorMessage,
  });

  final List<Article> items;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? categoryId;
  final String? errorMessage;

  bool get hasMore => page < totalPages;

  ArticlesListState copyWith({
    List<Article>? items,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? categoryId,
    bool clearCategoryId = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ArticlesListState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ArticlesListController extends StateNotifier<ArticlesListState> {
  ArticlesListController(this._repository) : super(const ArticlesListState()) {
    loadInitial();
  }

  final ArticlesRepository _repository;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.fetchArticles(page: 1, categoryId: state.categoryId);
      state = state.copyWith(
        items: result.items,
        page: result.page,
        totalPages: result.totalPages,
        isLoading: false,
      );
    } on DioException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '육아 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final result =
          await _repository.fetchArticles(page: state.page + 1, categoryId: state.categoryId);
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

  void setCategory(String? categoryId) {
    if (state.categoryId == categoryId) return;
    state = state.copyWith(categoryId: categoryId, clearCategoryId: categoryId == null);
    loadInitial();
  }
}

final articlesListControllerProvider =
    StateNotifierProvider.autoDispose<ArticlesListController, ArticlesListState>((ref) {
  return ArticlesListController(ref.watch(articlesRepositoryProvider));
});
