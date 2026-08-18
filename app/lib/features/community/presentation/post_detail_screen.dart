import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../admin/domain/ad.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/comment.dart';
import '../domain/post_detail.dart';
import 'community_controller.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    final message =
        await ref.read(postDetailControllerProvider(widget.postId).notifier).addComment(content);
    if (!mounted) return;
    setState(() => _isSubmittingComment = false);

    if (message == null) {
      _commentController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _editPost(PostDetail post) async {
    final updated = await context.push<bool>('/community/${post.id}/edit', extra: post);
    if (updated == true) {
      ref.read(postDetailControllerProvider(widget.postId).notifier).refresh();
    }
  }

  Future<void> _deletePost(PostDetail post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글을 삭제할까요?'),
        content: const Text('삭제하면 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(communityRepositoryProvider).deletePost(post.id);
      ref.read(postsListControllerProvider.notifier).loadInitial();
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final message =
        await ref.read(postDetailControllerProvider(widget.postId).notifier).deleteComment(commentId);
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(postDetailControllerProvider(widget.postId));
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        actions: [
          detailAsync.maybeWhen(
            data: (post) => post.authorId == currentUserId
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editPost(post);
                      if (value == 'delete') _deletePost(post);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('수정')),
                      PopupMenuItem(value: 'delete', child: Text('삭제')),
                    ],
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (post) => _PostDetailBody(
          post: post,
          currentUserId: currentUserId,
          onDeleteComment: _deleteComment,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('게시글을 불러오지 못했습니다.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.read(postDetailControllerProvider(widget.postId).notifier).refresh(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: '댓글을 입력하세요',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSubmittingComment ? null : _submitComment,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _PostDetailBody extends ConsumerWidget {
  const _PostDetailBody({
    required this.post,
    required this.currentUserId,
    required this.onDeleteComment,
  });

  final PostDetail post;
  final String? currentUserId;
  final void Function(String commentId) onDeleteComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (post.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported_outlined, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (post.category != null) ...[
          Text(
            post.category!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
        ],
        Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${post.authorNickname} · ${_formatDate(post.createdAt)} · 조회 ${post.viewCount}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Divider(height: 32),
        Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => ref.read(postDetailControllerProvider(post.id).notifier).toggleLike(),
          icon: Icon(
            post.likedByMe ? Icons.favorite : Icons.favorite_border,
            color: post.likedByMe ? Colors.red : null,
          ),
          label: Text('좋아요 ${post.likeCount}'),
        ),
        const SizedBox(height: 16),
        const AdBanner(placement: AdPlacement.postDetail),
        const Divider(height: 32),
        Text('댓글 ${post.comments.length}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (post.comments.isEmpty)
          const Text('아직 댓글이 없습니다.')
        else
          for (final comment in post.comments)
            _CommentTile(
              comment: comment,
              canDelete: comment.authorId == currentUserId,
              onDelete: () => onDeleteComment(comment.id),
            ),
        const SizedBox(height: 60),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.canDelete, required this.onDelete});

  final Comment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorNickname,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(comment.content),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: '댓글 삭제',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
