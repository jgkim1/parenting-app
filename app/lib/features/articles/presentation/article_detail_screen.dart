import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/article_detail.dart';
import 'articles_controller.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({required this.articleId, super.key});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(articleDetailProvider(articleId));

    return Scaffold(
      appBar: AppBar(title: const Text('육아 정보')),
      body: detailAsync.when(
        data: (article) => _ArticleDetailBody(article: article),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('아티클을 불러오지 못했습니다.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(articleDetailProvider(articleId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleDetailBody extends StatelessWidget {
  const _ArticleDetailBody({required this.article});

  final ArticleDetail article;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (article.thumbnailUrl != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                article.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported_outlined, size: 48),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          article.category.name,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(article.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${article.authorNickname} · ${_formatDate(article.createdAt)} · 조회 ${article.viewCount}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Divider(height: 32),
        Text(article.content, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
