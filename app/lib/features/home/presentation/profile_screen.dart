import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../children/domain/child.dart';
import '../../children/presentation/child_form_sheet.dart';
import '../../children/presentation/children_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openChildForm(BuildContext context, {Child? editing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ChildFormSheet(editing: editing),
    );
  }

  Future<void> _deleteChild(BuildContext context, WidgetRef ref, Child child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${child.nickname} 정보를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(childrenRepositoryProvider).deleteChild(child.id);
      ref.read(childrenControllerProvider.notifier).refresh();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final childrenAsync = ref.watch(childrenControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                (user?.nickname.isNotEmpty ?? false) ? user!.nickname.substring(0, 1) : '?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.nickname ?? '불러오는 중...',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (user != null)
                    Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('주문 내역'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/orders'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('장바구니'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/cart'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('자녀 정보', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => _openChildForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('자녀 추가'),
            ),
          ],
        ),
        childrenAsync.when(
          data: (children) {
            if (children.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('등록된 자녀 정보가 없습니다.'),
              );
            }
            return Column(
              children: [
                for (final child in children)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          switch (child.gender) {
                            ChildGender.male => Icons.boy_outlined,
                            ChildGender.female => Icons.girl_outlined,
                            _ => Icons.child_care_outlined,
                          },
                        ),
                      ),
                      title: Text(child.nickname),
                      subtitle: Text('생후 ${child.ageInMonths}개월'
                          '${child.gender != null ? ' · ${child.gender!.label}' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _openChildForm(context, editing: child),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _deleteChild(context, ref, child),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('자녀 정보를 불러오지 못했습니다.'),
          ),
        ),
        if (user?.role == 'ADMIN') ...[
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('관리자 모드'),
              subtitle: const Text('상품·육아정보·광고 관리'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          icon: const Icon(Icons.logout),
          label: const Text('로그아웃'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
