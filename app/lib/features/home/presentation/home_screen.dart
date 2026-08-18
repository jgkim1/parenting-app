import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/presentation/product_list_screen.dart';
import '../../articles/presentation/article_list_screen.dart';
import '../../community/presentation/post_list_screen.dart';
import '../../community/presentation/community_controller.dart';
import 'profile_screen.dart';
import 'today_screen.dart';

const _tabTitles = ['투데이', '육아 정보', '커뮤니티', '쇼핑', '내 정보'];
const _communityTabIndex = 2;

// 투데이/육아 정보/커뮤니티/쇼핑/내 정보를 화면 전환 없이 하단 탭으로 오갈 수 있도록 묶은 셸.
// IndexedStack이 각 탭의 위젯을 계속 마운트 상태로 유지하므로, 탭을 오가도
// 검색어·스크롤 위치·필터 같은 화면 상태가 그대로 보존된다.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  Future<void> _createPost() async {
    final createdPostId = await context.push<String>('/community/new');
    if (createdPostId != null) {
      ref.read(postsListControllerProvider.notifier).loadInitial();
    }
  }

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tabTitles[_currentIndex])),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TodayScreen(onSeeAllTapped: _goToTab),
          const ArticleListScreen(),
          const PostListScreen(),
          const ProductListScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == _communityTabIndex
          ? FloatingActionButton.extended(
              onPressed: _createPost,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('글쓰기'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), label: '투데이'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: '육아 정보'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), label: '커뮤니티'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: '쇼핑'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '내 정보'),
        ],
      ),
    );
  }
}
