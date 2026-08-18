import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../articles/domain/article_category.dart';
import '../../articles/presentation/articles_controller.dart';

// 육아정보(아티클) 등록/수정 화면을 겸한다. articleId가 있으면 수정, 없으면 신규 등록.
class AdminArticleFormScreen extends ConsumerStatefulWidget {
  const AdminArticleFormScreen({this.articleId, super.key});

  final String? articleId;

  bool get isEditing => articleId != null;

  @override
  ConsumerState<AdminArticleFormScreen> createState() => _AdminArticleFormScreenState();
}

class _AdminArticleFormScreenState extends ConsumerState<AdminArticleFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _categoryId;
  Uint8List? _pickedThumbnailBytes;
  String? _pickedThumbnailName;
  String? _existingThumbnailUrl;

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
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoadingDetail = true);
    try {
      final detail = await ref
          .read(articlesRepositoryProvider)
          .fetchArticleDetail(widget.articleId!, includeInactive: true);
      _titleController.text = detail.title;
      _contentController.text = detail.content;
      _categoryId = detail.category.id;
      _existingThumbnailUrl = detail.thumbnailUrl;
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '아티클 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedThumbnailBytes = bytes;
        _pickedThumbnailName = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('사진을 선택하지 못했습니다. 다시 시도해주세요.')));
    }
  }

  void _removeThumbnail() {
    setState(() {
      _pickedThumbnailBytes = null;
      _pickedThumbnailName = null;
      _existingThumbnailUrl = null;
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty || _categoryId == null) {
      setState(() => _errorMessage = '모든 항목을 올바르게 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(articlesRepositoryProvider);

    try {
      String? thumbnailUrl = _existingThumbnailUrl;
      if (_pickedThumbnailBytes != null && _pickedThumbnailName != null) {
        thumbnailUrl = await repository.uploadImage(
          bytes: _pickedThumbnailBytes!,
          filename: _pickedThumbnailName!,
        );
      }

      if (widget.isEditing) {
        await repository.updateArticle(
          widget.articleId!,
          categoryId: _categoryId,
          title: title,
          content: content,
          thumbnailUrl: thumbnailUrl,
        );
      } else {
        await repository.createArticle(
          categoryId: _categoryId!,
          title: title,
          content: content,
          thumbnailUrl: thumbnailUrl,
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
    final categoriesAsync = ref.watch(articleCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '육아정보 수정' : '육아정보 등록')),
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: '제목', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                    decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()),
                    items: [
                      for (final ArticleCategory category in categories)
                        DropdownMenuItem(value: category.id, child: Text(category.name)),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('카테고리를 불러오지 못했습니다.'),
                ),
                const SizedBox(height: 12),
                _buildThumbnailPicker(),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: '본문', border: OutlineInputBorder()),
                  maxLines: 10,
                ),
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

  Widget _buildThumbnailPicker() {
    final hasImage = _pickedThumbnailBytes != null || _existingThumbnailUrl != null;

    if (!hasImage) {
      return OutlinedButton.icon(
        onPressed: _pickThumbnail,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('썸네일 추가 (선택)'),
      );
    }

    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _pickedThumbnailBytes != null
                ? Image.memory(_pickedThumbnailBytes!, fit: BoxFit.cover, width: double.infinity)
                : Image.network(_existingThumbnailUrl!, fit: BoxFit.cover, width: double.infinity),
          ),
        ),
        IconButton.filled(
          onPressed: _removeThumbnail,
          icon: const Icon(Icons.close),
          tooltip: '썸네일 제거',
        ),
      ],
    );
  }
}
