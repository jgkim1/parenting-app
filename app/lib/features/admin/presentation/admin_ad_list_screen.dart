import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/ad.dart';
import 'admin_providers.dart';

class AdminAdListScreen extends ConsumerWidget {
  const AdminAdListScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, Ad ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${ad.title}" 광고를 삭제할까요?'),
        content: const Text('삭제하면 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adsRepositoryProvider).deleteAd(ad.id);
      ref.invalidate(adminAdsProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, Ad ad) async {
    try {
      await ref.read(adsRepositoryProvider).updateAd(ad.id, isActive: !ad.isActive);
      ref.invalidate(adminAdsProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('처리에 실패했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(adminAdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('광고 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/admin/ads/new');
          if (created == true) ref.invalidate(adminAdsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('광고 등록'),
      ),
      body: adsAsync.when(
        data: (ads) {
          if (ads.isEmpty) {
            return const Center(child: Text('등록된 광고가 없습니다.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminAdsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ads.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ad = ads[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(ad.imageUrl),
                      onBackgroundImageError: (_, _) {},
                    ),
                    title: Text(ad.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${ad.placement.label} · 순서 ${ad.sortOrder}${ad.isActive ? '' : ' · 노출 중지됨'}',
                      style: ad.isActive ? null : TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () async {
                            final updated =
                                await context.push<bool>('/admin/ads/${ad.id}/edit', extra: ad);
                            if (updated == true) ref.invalidate(adminAdsProvider);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            ad.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          tooltip: ad.isActive ? '노출 중지' : '다시 노출',
                          onPressed: () => _toggleActive(context, ref, ad),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _delete(context, ref, ad),
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
        error: (_, _) => const Center(child: Text('광고 목록을 불러오지 못했습니다.')),
      ),
    );
  }
}
