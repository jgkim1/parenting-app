import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/child.dart';
import 'children_controller.dart';

// 자녀 등록/수정 바텀시트. editing이 있으면 수정 모드로 기존 값을 채운다.
class ChildFormSheet extends ConsumerStatefulWidget {
  const ChildFormSheet({this.editing, super.key});

  final Child? editing;

  @override
  ConsumerState<ChildFormSheet> createState() => _ChildFormSheetState();
}

class _ChildFormSheetState extends ConsumerState<ChildFormSheet> {
  late final _nicknameController = TextEditingController(text: widget.editing?.nickname);
  late DateTime? _birthDate = widget.editing?.birthDate;
  late ChildGender? _gender = widget.editing?.gender;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty || _birthDate == null) {
      setState(() => _errorMessage = '이름과 생년월일을 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(childrenRepositoryProvider);
    try {
      if (widget.editing != null) {
        await repository.updateChild(
          widget.editing!.id,
          nickname: nickname,
          gender: _gender,
          birthDate: _birthDate!,
        );
      } else {
        await repository.createChild(nickname: nickname, gender: _gender, birthDate: _birthDate!);
      }
      await ref.read(childrenControllerProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop();
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
            widget.editing != null ? '자녀 정보 수정' : '자녀 등록',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(labelText: '이름(애칭)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickBirthDate,
            icon: const Icon(Icons.cake_outlined),
            label: Text(
              _birthDate == null
                  ? '생년월일 선택'
                  : '${_birthDate!.year}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.day.toString().padLeft(2, '0')}',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final gender in ChildGender.values)
                ChoiceChip(
                  label: Text(gender.label),
                  selected: _gender == gender,
                  onSelected: (_) => setState(() => _gender = gender),
                ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
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
