import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../admin/domain/ad.dart';
import '../../articles/domain/article.dart';
import '../../articles/presentation/articles_controller.dart';
import '../../community/domain/post.dart';
import '../../community/presentation/community_controller.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/products_controller.dart';

final _todayArticlesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(articlesRepositoryProvider).fetchArticles(page: 1);
});

final _todayPostsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(communityRepositoryProvider).fetchPosts(page: 1);
});

final _todayProductsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(productsRepositoryProvider).fetchProducts(page: 1);
});

// 육아 정보 · 커뮤니티 · 쇼핑의 최신 콘텐츠를 한 화면에서 훑어볼 수 있는 대시보드.
// 각 섹션의 "더보기"는 해당 탭으로 전환하고, 카드를 탭하면 바로 상세로 이동한다.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({required this.onSeeAllTapped, super.key});

  final void Function(int tabIndex) onSeeAllTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(_todayArticlesProvider);
    final postsAsync = ref.watch(_todayPostsProvider);
    final productsAsync = ref.watch(_todayProductsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_todayArticlesProvider);
        ref.invalidate(_todayPostsProvider);
        ref.invalidate(_todayProductsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _SectionHeader(title: '육아 정보', onSeeAll: () => onSeeAllTapped(1)),
          SizedBox(
            height: 176,
            child: articlesAsync.when(
              data: (page) => _ArticleRow(articles: page.items.take(5).toList()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const _SectionError(),
            ),
          ),
          const SizedBox(height: 16),
          const AdBanner(placement: AdPlacement.today),
          const SizedBox(height: 8),
          _SectionHeader(title: '커뮤니티', onSeeAll: () => onSeeAllTapped(2)),
          postsAsync.when(
            data: (page) => _PostColumn(posts: page.items.take(4).toList()),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const _SectionError(),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: '쇼핑', onSeeAll: () => onSeeAllTapped(3)),
          SizedBox(
            height: 210,
            child: productsAsync.when(
              data: (page) => _ProductRow(products: page.items.take(5).toList()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const _SectionError(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          TextButton(onPressed: onSeeAll, child: const Text('더보기 >')),
        ],
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('불러오지 못했습니다.'));
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.articles});

  final List<Article> articles;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const Center(child: Text('등록된 정보가 없습니다.'));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: articles.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final article = articles[index];
        return SizedBox(
          width: 150,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/articles/${article.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: article.thumbnailUrl != null
                          ? Image.network(
                              article.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported_outlined),
                            )
                          : const Icon(Icons.menu_book_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostColumn extends StatelessWidget {
  const _PostColumn({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('등록된 게시글이 없습니다.'),
      );
    }
    return Column(
      children: [
        for (final post in posts)
          ListTile(
            onTap: () => context.push('/community/${post.id}'),
            leading: post.imageUrl == null
                ? const CircleAvatar(child: Icon(Icons.forum_outlined))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
            title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${post.authorNickname} · 좋아요 ${post.likeCount} · 댓글 ${post.commentCount}'),
          ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('등록된 상품이 없습니다.'));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final product = products[index];
        return SizedBox(
          width: 140,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/products/${product.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: product.thumbnailUrl != null
                          ? Image.network(
                              product.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported_outlined),
                            )
                          : const Icon(Icons.image_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${formatPriceKrw(product.price)}원',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
