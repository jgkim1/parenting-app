import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리자 모드')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminMenuCard(
            icon: Icons.shopping_bag_outlined,
            title: '상품 관리',
            subtitle: '상품 등록·수정, 판매 중지',
            onTap: () => context.push('/admin/products'),
          ),
          const SizedBox(height: 12),
          _AdminMenuCard(
            icon: Icons.menu_book_outlined,
            title: '육아정보 관리',
            subtitle: '아티클 등록·수정·삭제',
            onTap: () => context.push('/admin/articles'),
          ),
          const SizedBox(height: 12),
          _AdminMenuCard(
            icon: Icons.campaign_outlined,
            title: '광고 관리',
            subtitle: '배너 등록·수정·삭제',
            onTap: () => context.push('/admin/ads'),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
