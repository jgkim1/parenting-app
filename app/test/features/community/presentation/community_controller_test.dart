import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parenting_app/features/community/data/community_repository.dart';
import 'package:parenting_app/features/community/domain/comment.dart';
import 'package:parenting_app/features/community/domain/post.dart';
import 'package:parenting_app/features/community/domain/post_detail.dart';
import 'package:parenting_app/features/community/presentation/community_controller.dart';

import '../../../support/flush.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

Post _post(String title) => Post.fromJson({
      'id': title,
      'title': title,
      'category': null,
      'imageUrl': null,
      'viewCount': 0,
      'createdAt': '2026-08-14T00:00:00.000Z',
      'author': {'id': 'u1', 'nickname': '작성자'},
      '_count': {'comments': 0, 'likes': 0},
    });

PostDetail _postDetail({bool likedByMe = false, int likeCount = 0, List<Comment>? comments}) {
  return PostDetail(
    id: 'post1',
    title: '제목',
    content: '내용',
    category: null,
    imageUrl: null,
    viewCount: 1,
    createdAt: DateTime(2026, 8, 14),
    authorId: 'u1',
    authorNickname: '작성자',
    likeCount: likeCount,
    likedByMe: likedByMe,
    comments: comments ?? [],
  );
}

Comment _comment(String id) => Comment(
      id: id,
      content: '댓글 $id',
      authorId: 'u2',
      authorNickname: '댓글러',
      createdAt: DateTime(2026, 8, 14),
    );

DioException _errorWithMessage(String message) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/posts'),
    response: Response(
      requestOptions: RequestOptions(path: '/api/posts'),
      statusCode: 400,
      data: {'message': message},
    ),
  );
}

void main() {
  late MockCommunityRepository repository;

  setUp(() {
    repository = MockCommunityRepository();
  });

  group('PostsListController', () {
    test('생성 시 1페이지를 불러온다', () async {
      when(() => repository.fetchPosts(page: 1, q: ''))
          .thenAnswer((_) async => PostPage(items: [_post('a')], page: 1, totalPages: 1));

      final controller = PostsListController(repository);
      await flushMicrotasks();

      expect(controller.state.items, hasLength(1));
      expect(controller.state.isLoading, isFalse);
    });

    test('검색어를 바꾸면 1페이지부터 다시 불러온다', () async {
      when(() => repository.fetchPosts(page: 1, q: ''))
          .thenAnswer((_) async => PostPage(items: [_post('a')], page: 1, totalPages: 1));
      when(() => repository.fetchPosts(page: 1, q: '수유'))
          .thenAnswer((_) async => PostPage(items: [_post('수유')], page: 1, totalPages: 1));

      final controller = PostsListController(repository);
      await flushMicrotasks();

      controller.search('수유');
      await flushMicrotasks();

      expect(controller.state.items.single.title, '수유');
    });
  });

  group('PostDetailController.addComment', () {
    test('성공하면 댓글 목록에 낙관적으로 즉시 추가된다', () async {
      when(() => repository.fetchPostDetail('post1')).thenAnswer((_) async => _postDetail());
      when(() => repository.addComment('post1', '반가워요')).thenAnswer((_) async => _comment('c1'));

      final controller = PostDetailController(repository, 'post1');
      await flushMicrotasks();

      final message = await controller.addComment('반가워요');

      expect(message, isNull);
      expect(controller.state.value?.comments, hasLength(1));
      expect(controller.state.value?.comments.single.content, '댓글 c1');
    });

    test('실패하면 에러 메시지를 반환하고 댓글 목록은 그대로다', () async {
      when(() => repository.fetchPostDetail('post1')).thenAnswer((_) async => _postDetail());
      when(() => repository.addComment('post1', any())).thenThrow(_errorWithMessage('댓글 내용을 입력해주세요.'));

      final controller = PostDetailController(repository, 'post1');
      await flushMicrotasks();

      final message = await controller.addComment('');

      expect(message, '댓글 내용을 입력해주세요.');
      expect(controller.state.value?.comments, isEmpty);
    });
  });

  group('PostDetailController.deleteComment', () {
    test('성공하면 해당 댓글만 목록에서 사라진다', () async {
      when(() => repository.fetchPostDetail('post1'))
          .thenAnswer((_) async => _postDetail(comments: [_comment('c1'), _comment('c2')]));
      when(() => repository.deleteComment('c1')).thenAnswer((_) async {});

      final controller = PostDetailController(repository, 'post1');
      await flushMicrotasks();

      final message = await controller.deleteComment('c1');

      expect(message, isNull);
      expect(controller.state.value?.comments.map((c) => c.id), ['c2']);
    });
  });

  group('PostDetailController.toggleLike', () {
    test('성공하면 likedByMe/likeCount가 서버 응답으로 갱신된다', () async {
      when(() => repository.fetchPostDetail('post1'))
          .thenAnswer((_) async => _postDetail(likedByMe: false, likeCount: 0));
      when(() => repository.toggleLike('post1')).thenAnswer((_) async => (liked: true, likeCount: 1));

      final controller = PostDetailController(repository, 'post1');
      await flushMicrotasks();

      await controller.toggleLike();

      expect(controller.state.value?.likedByMe, isTrue);
      expect(controller.state.value?.likeCount, 1);
    });

    test('실패하면 조용히 무시하고 이전 상태를 유지한다', () async {
      when(() => repository.fetchPostDetail('post1'))
          .thenAnswer((_) async => _postDetail(likedByMe: false, likeCount: 0));
      when(() => repository.toggleLike('post1')).thenThrow(_errorWithMessage('오류'));

      final controller = PostDetailController(repository, 'post1');
      await flushMicrotasks();

      await controller.toggleLike();

      expect(controller.state.value?.likedByMe, isFalse);
      expect(controller.state.value?.likeCount, 0);
    });
  });
}
