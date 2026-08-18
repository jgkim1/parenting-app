import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../articles/domain/article.dart';
import '../../articles/presentation/articles_controller.dart' show articlesRepositoryProvider;
import 'admin_providers.dart';

class AdminArticleListScreen extends ConsumerWidget {
  const AdminArticleListScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, Article article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${article.title}"을(를) 삭제할까요?'),
        content: const Text('삭제하면 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(articlesRepositoryProvider).deleteArticle(article.id);
      ref.invalidate(adminArticlesProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, Article article) async {
    try {
      await ref
          .read(articlesRepositoryProvider)
          .updateArticle(article.id, isActive: !article.isActive);
      ref.invalidate(adminArticlesProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('처리에 실패했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(adminArticlesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('육아정보 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/admin/articles/new');
          if (created == true) ref.invalidate(adminArticlesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('아티클 등록'),
      ),
      body: articlesAsync.when(
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(child: Text('등록된 육아정보가 없습니다.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminArticlesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: articles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final article = articles[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          article.thumbnailUrl != null ? NetworkImage(article.thumbnailUrl!) : null,
                      child: article.thumbnailUrl == null ? const Icon(Icons.menu_book_outlined) : null,
                    ),
                    title: Text(article.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${article.category.name}${article.isActive ? '' : ' · 비공개'}',
                      style:
                          article.isActive ? null : TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () async {
                            final updated =
                                await context.push<bool>('/admin/articles/${article.id}/edit');
                            if (updated == true) ref.invalidate(adminArticlesProvider);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            article.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          tooltip: article.isActive ? '비공개로 전환' : '공개로 전환',
                          onPressed: () => _toggleActive(context, ref, article),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _delete(context, ref, article),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('육아정보 목록을 불러오지 못했습니다.')),
      ),
    );
  }
}
