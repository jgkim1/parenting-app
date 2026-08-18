import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/products_controller.dart' show productsRepositoryProvider;
import 'admin_providers.dart';

class AdminProductListScreen extends ConsumerWidget {
  const AdminProductListScreen({super.key});

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, Product product) async {
    final activating = !product.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activating ? '${product.name}을(를) 다시 노출할까요?' : '${product.name}을(를) 판매 중지할까요?'),
        content: activating ? null : const Text('판매 중지하면 쇼핑 목록/상세에서 즉시 사라집니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(activating ? '노출' : '판매 중지'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(productsRepositoryProvider).updateProduct(product.id, isActive: activating);
      ref.invalidate(adminProductsProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('처리에 실패했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('상품 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/admin/products/new');
          if (created == true) ref.invalidate(adminProductsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('상품 등록'),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('등록된 상품이 없습니다.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminProductsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          product.thumbnailUrl != null ? NetworkImage(product.thumbnailUrl!) : null,
                      child: product.thumbnailUrl == null ? const Icon(Icons.shopping_bag_outlined) : null,
                    ),
                    title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${product.category.name} · ${product.price}원 · 재고 ${product.stock}'
                      '${product.isActive ? '' : ' · 판매 중지됨'}',
                      style: product.isActive
                          ? null
                          : TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () async {
                            final updated =
                                await context.push<bool>('/admin/products/${product.id}/edit');
                            if (updated == true) ref.invalidate(adminProductsProvider);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            product.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          tooltip: product.isActive ? '판매 중지(삭제)' : '다시 노출',
                          onPressed: () => _toggleActive(context, ref, product),
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
        error: (_, _) => const Center(child: Text('상품 목록을 불러오지 못했습니다.')),
      ),
    );
  }
}
