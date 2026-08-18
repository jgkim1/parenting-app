import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../admin/domain/ad.dart';
import '../domain/post.dart';
import 'community_controller.dart';

// 목록에서 이 위치(0-based) 뒤에 광고를 한 번 끼워 넣는다. 목록이 이보다 짧으면 넣지 않는다.
const _adAfterIndex = 2;

class PostListScreen extends ConsumerStatefulWidget {
  const PostListScreen({super.key});

  @override
  ConsumerState<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends ConsumerState<PostListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(postsListControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postsListControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '제목이나 내용으로 검색',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onSubmitted: (value) =>
                ref.read(postsListControllerProvider.notifier).search(value.trim()),
          ),
        ),
        Expanded(child: _buildBody(state)),
      ],
    );
  }

  Widget _buildBody(PostsListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(child: Text(state.errorMessage!));
    }

    if (state.items.isEmpty) {
      return const Center(child: Text('등록된 게시글이 없습니다.'));
    }

    final hasAdSlot = state.items.length > _adAfterIndex + 1;

    return RefreshIndicator(
      onRefresh: () => ref.read(postsListControllerProvider.notifier).loadInitial(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.items.length + (hasAdSlot ? 1 : 0) + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (hasAdSlot && index == _adAfterIndex + 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: AdBanner(placement: AdPlacement.communityList),
            );
          }
          final itemIndex = hasAdSlot && index > _adAfterIndex + 1 ? index - 1 : index;
          if (itemIndex >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = state.items[itemIndex];
          return _PostListTile(
            post: post,
            onTap: () => context.push('/community/${post.id}'),
          );
        },
      ),
    );
  }
}

class _PostListTile extends StatelessWidget {
  const _PostListTile({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: post.imageUrl == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported_outlined),
              ),
            ),
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${post.authorNickname} · ${_formatDate(post.createdAt)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 16),
          const SizedBox(width: 2),
          Text('${post.likeCount}'),
          const SizedBox(width: 10),
          const Icon(Icons.mode_comment_outlined, size: 16),
          const SizedBox(width: 2),
          Text('${post.commentCount}'),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
