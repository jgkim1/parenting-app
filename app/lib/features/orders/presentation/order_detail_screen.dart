import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../domain/order.dart';
import 'orders_controller.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('주문 상세')),
      body: orderAsync.when(
        data: (order) => _OrderDetailBody(order: order),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('주문 정보를 불러오지 못했습니다.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(orderStatusLabel(order.status)),
        ),
        const SizedBox(height: 12),
        Text('주문번호 ${order.id}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text('배송지: ${order.shippingAddr}', style: Theme.of(context).textTheme.bodyMedium),
        const Divider(height: 32),
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 56,
                    height: 56,
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
                        '${formatPriceKrw(item.priceAtOrder)}원 x ${item.quantity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text('${formatPriceKrw(item.subtotal)}원'),
              ],
            ),
          ),
        const Divider(height: 8),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('총 결제 금액', style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${formatPriceKrw(order.totalAmount)}원',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
