import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../admin/domain/ad.dart';
import '../domain/article.dart';
import 'articles_controller.dart';

// 목록에서 이 위치(0-based) 뒤에 광고를 한 번 끼워 넣는다. 목록이 이보다 짧으면 넣지 않는다.
const _adAfterIndex = 1;

class ArticleListScreen extends ConsumerStatefulWidget {
  const ArticleListScreen({super.key});

  @override
  ConsumerState<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends ConsumerState<ArticleListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(articlesListControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articlesListControllerProvider);
    final categoriesAsync = ref.watch(articleCategoriesProvider);

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: categoriesAsync.when(
            data: (categories) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _CategoryChip(
                  label: '전체',
                  selected: state.categoryId == null,
                  onTap: () => ref.read(articlesListControllerProvider.notifier).setCategory(null),
                ),
                for (final category in categories)
                  _CategoryChip(
                    label: category.name,
                    selected: state.categoryId == category.id,
                    onTap: () =>
                        ref.read(articlesListControllerProvider.notifier).setCategory(category.id),
                  ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody(state)),
      ],
    );
  }

  Widget _buildBody(ArticlesListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(child: Text(state.errorMessage!));
    }

    if (state.items.isEmpty) {
      return const Center(child: Text('등록된 정보가 없습니다.'));
    }

    final hasAdSlot = state.items.length > _adAfterIndex + 1;

    return RefreshIndicator(
      onRefresh: () => ref.read(articlesListControllerProvider.notifier).loadInitial(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length + (hasAdSlot ? 1 : 0) + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (hasAdSlot && index == _adAfterIndex + 1) {
            return const AdBanner(placement: AdPlacement.articleList, style: AdBannerStyle.native);
          }
          final itemIndex = hasAdSlot && index > _adAfterIndex + 1 ? index - 1 : index;
          if (itemIndex >= state.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final article = state.items[itemIndex];
          return _ArticleCard(
            article: article,
            onTap: () => context.push('/articles/${article.id}'),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                width: double.infinity,
                child: article.thumbnailUrl != null
                    ? Image.network(
                        article.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined),
                      )
                    : const Icon(Icons.menu_book_outlined, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.category.name,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
