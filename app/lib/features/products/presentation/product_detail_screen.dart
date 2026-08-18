import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../admin/domain/ad.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cart/presentation/cart_controller.dart';
import '../domain/product_detail.dart';
import 'products_controller.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('상품 상세')),
      body: detailAsync.when(
        data: (product) => _ProductDetailBody(product: product),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('상품 정보를 불러오지 못했습니다.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(productDetailProvider(productId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (product) => _AddToCartBar(product: product),
        orElse: () => null,
      ),
    );
  }
}

class _AddToCartBar extends ConsumerStatefulWidget {
  const _AddToCartBar({required this.product});

  final ProductDetail product;

  @override
  ConsumerState<_AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends ConsumerState<_AddToCartBar> {
  bool _isAdding = false;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    final message = await ref.read(cartControllerProvider.notifier).addItem(widget.product.id);
    if (!mounted) return;
    setState(() => _isAdding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? '장바구니에 담았습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inStock = widget.product.stock > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: !inStock || _isAdding ? null : _addToCart,
            icon: _isAdding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_shopping_cart_outlined),
            label: Text(inStock ? '장바구니 담기' : '품절'),
          ),
        ),
      ),
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  const _ProductDetailBody({required this.product});

  final ProductDetail product;

  Future<void> _openReviewForm(
    BuildContext context,
    WidgetRef ref, {
    ProductReview? editing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReviewFormSheet(productId: product.id, editing: editing),
    );
    if (saved == true) {
      ref.invalidate(productDetailProvider(product.id));
    }
  }

  Future<void> _deleteReview(BuildContext context, WidgetRef ref, String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('리뷰를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(productsRepositoryProvider).deleteReview(reviewId);
      ref.invalidate(productDetailProvider(product.id));
    } on DioException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
    ProductReview? myReview;
    if (currentUserId != null) {
      for (final review in product.reviews) {
        if (review.authorId == currentUserId) {
          myReview = review;
          break;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.imageUrls.isNotEmpty
                ? PageView(
                    children: [
                      for (final url in product.imageUrls)
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported_outlined, size: 48),
                        ),
                    ],
                  )
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image_outlined, size: 48),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(product.category.name, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${formatPriceKrw(product.price)}원',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          product.stock > 0 ? '재고 ${product.stock}개' : '품절',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: product.stock > 0 ? null : Theme.of(context).colorScheme.error,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, size: 18, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              product.reviewStats.count > 0
                  ? '${product.reviewStats.average.toStringAsFixed(1)} (${product.reviewStats.count}개 리뷰)'
                  : '아직 평점이 없습니다',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('판매자: ${product.sellerNickname}', style: Theme.of(context).textTheme.bodySmall),
        const Divider(height: 32),
        Text('상품 설명', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(product.description),
        const SizedBox(height: 16),
        const AdBanner(placement: AdPlacement.productDetail),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('리뷰 (${product.reviews.length})', style: Theme.of(context).textTheme.titleMedium),
            if (currentUserId != null && myReview == null)
              TextButton.icon(
                onPressed: () => _openReviewForm(context, ref),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('리뷰 작성'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (product.reviews.isEmpty)
          const Text('아직 등록된 리뷰가 없습니다.')
        else
          for (final review in product.reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(review.authorNickname, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      if (review.authorId == currentUserId) ...[
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: '리뷰 수정',
                          onPressed: () => _openReviewForm(context, ref, editing: review),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: '리뷰 삭제',
                          onPressed: () => _deleteReview(context, ref, review.id),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(review.content),
                ],
              ),
            ),
      ],
    );
  }
}

class _ReviewFormSheet extends ConsumerStatefulWidget {
  const _ReviewFormSheet({required this.productId, this.editing});

  final String productId;
  final ProductReview? editing;

  @override
  ConsumerState<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<_ReviewFormSheet> {
  late int _rating = widget.editing?.rating ?? 5;
  late final _contentController = TextEditingController(text: widget.editing?.content);
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _errorMessage = '리뷰 내용을 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(productsRepositoryProvider);
    try {
      if (widget.editing != null) {
        await repository.updateReview(widget.editing!.id, rating: _rating, content: content);
      } else {
        await repository.createReview(widget.productId, rating: _rating, content: content);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] is String)
          ? data['message'] as String
          : '리뷰 저장에 실패했습니다. 잠시 후 다시 시도해주세요.';
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.editing != null ? '리뷰 수정' : '리뷰 작성',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: '상품에 대한 솔직한 리뷰를 남겨주세요.',
              border: OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 5,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}
