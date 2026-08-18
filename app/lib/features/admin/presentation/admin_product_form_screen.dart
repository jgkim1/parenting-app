import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../products/domain/category.dart';
import '../../products/presentation/products_controller.dart';

// 상품 등록/수정 화면을 겸한다. productId가 있으면 해당 상품을 불러와 수정하고,
// 없으면 새 상품을 등록한다.
class AdminProductFormScreen extends ConsumerStatefulWidget {
  const AdminProductFormScreen({this.productId, super.key});

  final String? productId;

  bool get isEditing => productId != null;

  @override
  ConsumerState<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends ConsumerState<AdminProductFormScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _categoryId;
  final List<String> _imageUrls = [];
  final List<({Uint8List bytes, String name})> _pendingImages = [];

  bool _isLoadingDetail = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadDetail();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoadingDetail = true);
    try {
      final detail =
          await ref.read(productsRepositoryProvider).fetchProductDetail(widget.productId!);
      _nameController.text = detail.name;
      _descriptionController.text = detail.description;
      _priceController.text = detail.price.toString();
      _stockController.text = detail.stock.toString();
      _categoryId = detail.category.id;
      _imageUrls.addAll(detail.imageUrls);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '상품 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _pendingImages.add((bytes: bytes, name: file.name)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('사진을 선택하지 못했습니다. 다시 시도해주세요.')));
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = int.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (name.isEmpty || description.isEmpty || _categoryId == null || price == null || stock == null) {
      setState(() => _errorMessage = '모든 항목을 올바르게 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(productsRepositoryProvider);

    try {
      final uploadedUrls = <String>[
        ..._imageUrls,
        for (final pending in _pendingImages)
          await repository.uploadImage(bytes: pending.bytes, filename: pending.name),
      ];

      if (widget.isEditing) {
        await repository.updateProduct(
          widget.productId!,
          categoryId: _categoryId,
          name: name,
          description: description,
          price: price,
          stock: stock,
          imageUrls: uploadedUrls,
        );
      } else {
        await repository.createProduct(
          categoryId: _categoryId!,
          name: name,
          description: description,
          price: price,
          stock: stock,
          imageUrls: uploadedUrls,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] is String)
          ? data['message'] as String
          : '저장에 실패했습니다. 잠시 후 다시 시도해주세요.';
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '상품 수정' : '상품 등록')),
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '상품명', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                    decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()),
                    items: [
                      for (final Category category in categories)
                        DropdownMenuItem(value: category.id, child: Text(category.name)),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('카테고리를 불러오지 못했습니다.'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        decoration:
                            const InputDecoration(labelText: '가격(원)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _stockController,
                        decoration: const InputDecoration(labelText: '재고', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: '상품 설명', border: OutlineInputBorder()),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                _buildImagePicker(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isEditing ? '수정 완료' : '등록'),
                ),
              ],
            ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('상품 이미지', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _imageUrls.length; i++)
              _buildThumb(
                image: Image.network(_imageUrls[i], fit: BoxFit.cover),
                onRemove: () => setState(() => _imageUrls.removeAt(i)),
              ),
            for (var i = 0; i < _pendingImages.length; i++)
              _buildThumb(
                image: Image.memory(_pendingImages[i].bytes, fit: BoxFit.cover),
                onRemove: () => setState(() => _pendingImages.removeAt(i)),
              ),
            OutlinedButton(
              onPressed: _pickImage,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(72, 72),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThumb({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 72, height: 72, child: image),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            icon: const Icon(Icons.cancel, size: 20),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}
