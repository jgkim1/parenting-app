import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/formatters.dart';
import '../domain/cart.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _showError(BuildContext context, String message) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('장바구니')),
      body: cartAsync.when(
        data: (cart) => cart.isEmpty
            ? const Center(child: Text('장바구니가 비어 있습니다.'))
            : _CartBody(cart: cart, onError: (msg) => _showError(context, msg)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('장바구니를 불러오지 못했습니다.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.read(cartControllerProvider.notifier).refresh(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBody extends ConsumerWidget {
  const _CartBody({required this.cart, required this.onError});

  final Cart cart;
  final void Function(String) onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cartControllerProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: item.thumbnailUrl != null
                          ? Image.network(
                              item.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported_outlined),
                            )
                          : const Icon(Icons.image_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          '${formatPriceKrw(item.subtotal)}원',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: item.quantity <= 1
                            ? null
                            : () async {
                                final message = await controller.updateItem(
                                  item.productId,
                                  item.quantity - 1,
                                );
                                if (message != null) onError(message);
                              },
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: item.quantity >= item.stock
                            ? null
                            : () async {
                                final message = await controller.updateItem(
                                  item.productId,
                                  item.quantity + 1,
                                );
                                if (message != null) onError(message);
                              },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => controller.removeItem(item.productId),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('총 ${cart.totalQuantity}개', style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        '${formatPriceKrw(cart.totalAmount)}원',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => context.push('/checkout'),
                  child: const Text('주문하기'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
