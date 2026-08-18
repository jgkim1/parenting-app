import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/ad.dart';
import 'admin_providers.dart';

// 광고 등록/수정 화면을 겸한다. editing이 있으면 수정, 없으면 신규 등록.
class AdminAdFormScreen extends ConsumerStatefulWidget {
  const AdminAdFormScreen({this.editing, super.key});

  final Ad? editing;

  bool get isEditing => editing != null;

  @override
  ConsumerState<AdminAdFormScreen> createState() => _AdminAdFormScreenState();
}

class _AdminAdFormScreenState extends ConsumerState<AdminAdFormScreen> {
  late final _titleController = TextEditingController(text: widget.editing?.title);
  late final _linkUrlController = TextEditingController(text: widget.editing?.linkUrl);
  late final _sortOrderController =
      TextEditingController(text: (widget.editing?.sortOrder ?? 0).toString());

  late AdPlacement _placement = widget.editing?.placement ?? AdPlacement.today;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  late String? _existingImageUrl = widget.editing?.imageUrl;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _linkUrlController.dispose();
    _sortOrderController.dispose();
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
          .showSnackBar(const SnackBar(content: Text('이미지를 선택하지 못했습니다. 다시 시도해주세요.')));
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final linkUrl = _linkUrlController.text.trim();
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final hasImage = _pickedImageBytes != null || _existingImageUrl != null;

    if (title.isEmpty || !hasImage) {
      setState(() => _errorMessage = '제목과 이미지는 필수입니다.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(adsRepositoryProvider);

    try {
      var imageUrl = _existingImageUrl;
      if (_pickedImageBytes != null && _pickedImageName != null) {
        imageUrl = await repository.uploadImage(
          bytes: _pickedImageBytes!,
          filename: _pickedImageName!,
        );
      }

      if (widget.isEditing) {
        await repository.updateAd(
          widget.editing!.id,
          placement: _placement,
          title: title,
          imageUrl: imageUrl,
          linkUrl: linkUrl.isEmpty ? null : linkUrl,
          sortOrder: sortOrder,
        );
      } else {
        await repository.createAd(
          placement: _placement,
          title: title,
          imageUrl: imageUrl!,
          linkUrl: linkUrl.isEmpty ? null : linkUrl,
          sortOrder: sortOrder,
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '광고 수정' : '광고 등록')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<AdPlacement>(
            initialValue: _placement,
            decoration: const InputDecoration(labelText: '삽입 위치', border: OutlineInputBorder()),
            items: [
              for (final placement in AdPlacement.values)
                DropdownMenuItem(value: placement, child: Text(placement.label)),
            ],
            onChanged: (value) => setState(() => _placement = value ?? _placement),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: '광고 제목', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkUrlController,
            decoration: const InputDecoration(
              labelText: '연결 링크 (선택)',
              hintText: 'https://...',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sortOrderController,
            decoration: const InputDecoration(
              labelText: '노출 순서 (작을수록 먼저)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
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
    final hasImage = _pickedImageBytes != null || _existingImageUrl != null;

    if (!hasImage) {
      return OutlinedButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('광고 이미지 추가'),
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
          onPressed: () => setState(() {
            _pickedImageBytes = null;
            _pickedImageName = null;
            _existingImageUrl = null;
          }),
          icon: const Icon(Icons.close),
          tooltip: '이미지 제거',
        ),
      ],
    );
  }
}
