import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/post_detail.dart';
import 'community_controller.dart';

// 글쓰기와 게시글 수정 화면을 겸한다. editingPost가 있으면 해당 게시글을 수정하고,
// 없으면 새 게시글을 작성한다.
class PostFormScreen extends ConsumerStatefulWidget {
  const PostFormScreen({this.editingPost, super.key});

  final PostDetail? editingPost;

  @override
  ConsumerState<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends ConsumerState<PostFormScreen> {
  late final _titleController = TextEditingController(text: widget.editingPost?.title);
  late final _contentController = TextEditingController(text: widget.editingPost?.content);
  late final _categoryController = TextEditingController(text: widget.editingPost?.category);

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  late String? _existingImageUrl = widget.editingPost?.imageUrl;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.editingPost != null;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('사진을 선택하지 못했습니다. 다시 시도해주세요.')));
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageName = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => _errorMessage = '제목과 내용을 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(communityRepositoryProvider);

    try {
      String? imageUrl = _existingImageUrl;
      if (_pickedImageBytes != null && _pickedImageName != null) {
        imageUrl = await repository.uploadImage(
          bytes: _pickedImageBytes!,
          filename: _pickedImageName!,
        );
      }

      final category = _categoryController.text.trim();

      if (_isEditing) {
        await repository.updatePost(
          widget.editingPost!.id,
          title: title,
          content: content,
          category: category,
          imageUrl: imageUrl,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        final post = await repository.createPost(
          title: title,
          content: content,
          category: category,
          imageUrl: imageUrl,
        );
        if (!mounted) return;
        Navigator.of(context).pop(post.id);
      }
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '게시글 수정' : '글쓰기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: '카테고리 (선택)',
                hintText: '예: 자유, 질문, 정보공유',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _buildImagePicker(context),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: '내용', border: OutlineInputBorder()),
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? '수정 완료' : '등록'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final hasImage = _pickedImageBytes != null || _existingImageUrl != null;

    if (!hasImage) {
      return OutlinedButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('사진 추가 (선택)'),
      );
    }

    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _pickedImageBytes != null
                ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover, width: double.infinity)
                : Image.network(_existingImageUrl!, fit: BoxFit.cover, width: double.infinity),
          ),
        ),
        IconButton.filled(
          onPressed: _removeImage,
          icon: const Icon(Icons.close),
          tooltip: '사진 제거',
        ),
      ],
    );
  }
}
