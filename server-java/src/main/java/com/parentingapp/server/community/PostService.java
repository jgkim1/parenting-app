package com.parentingapp.server.community;

import com.parentingapp.server.common.dto.PageResponse;
import com.parentingapp.server.common.exception.ForbiddenException;
import com.parentingapp.server.common.exception.NotFoundException;
import com.parentingapp.server.community.dto.CommentResponse;
import com.parentingapp.server.community.dto.CreateCommentRequest;
import com.parentingapp.server.community.dto.CreatePostRequest;
import com.parentingapp.server.community.dto.LikeToggleResponse;
import com.parentingapp.server.community.dto.PostDetailResponse;
import com.parentingapp.server.community.dto.PostSummaryResponse;
import com.parentingapp.server.community.dto.UpdatePostRequest;
import com.parentingapp.server.domain.Comment;
import com.parentingapp.server.domain.Like;
import com.parentingapp.server.domain.Post;
import com.parentingapp.server.domain.User;
import com.parentingapp.server.repository.CommentRepository;
import com.parentingapp.server.repository.LikeRepository;
import com.parentingapp.server.repository.PostRepository;
import com.parentingapp.server.repository.UserRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PostService {

    private final PostRepository postRepository;
    private final CommentRepository commentRepository;
    private final LikeRepository likeRepository;
    private final UserRepository userRepository;

    public PostService(
            PostRepository postRepository,
            CommentRepository commentRepository,
            LikeRepository likeRepository,
            UserRepository userRepository) {
        this.postRepository = postRepository;
        this.commentRepository = commentRepository;
        this.likeRepository = likeRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public PageResponse<PostSummaryResponse> listPosts(int page, int pageSize, String category, String q) {
        String query = (q == null || q.isBlank()) ? null : q;
        String categoryFilter = (category == null || category.isBlank()) ? null : category;
        Page<Post> result = postRepository.search(
                categoryFilter, query, PageRequest.of(page - 1, pageSize, Sort.by(Sort.Direction.DESC, "createdAt")));
        Page<PostSummaryResponse> mapped = result.map(post -> PostSummaryResponse.from(
                post, commentRepository.countByPost_Id(post.getId()), likeRepository.countByPost_Id(post.getId())));
        return PageResponse.of(mapped, page, pageSize);
    }

    @Transactional
    public PostDetailResponse getPostById(String id, String currentUserId) {
        Post post = postRepository.findById(id).orElseThrow(() -> new NotFoundException("게시글을 찾을 수 없습니다."));

        post.setViewCount(post.getViewCount() + 1);
        postRepository.saveAndFlush(post);

        var comments = commentRepository
                .findByPost_IdOrderByCreatedAtAsc(id, Pageable.ofSize(50))
                .stream()
                .map(CommentResponse::from)
                .toList();
        long likeCount = likeRepository.countByPost_Id(id);
        boolean likedByMe = currentUserId != null && likeRepository.findByPost_IdAndUser_Id(id, currentUserId).isPresent();

        return PostDetailResponse.from(post, comments, likeCount, likedByMe);
    }

    @Transactional
    public PostDetailResponse createPost(String authorId, CreatePostRequest input) {
        User author = userRepository.findById(authorId).orElseThrow(NotFoundException::new);
        Post post = new Post();
        post.setAuthor(author);
        post.setTitle(input.title());
        post.setContent(input.content());
        post.setCategory(input.category());
        post.setImageUrl(input.imageUrl());
        postRepository.saveAndFlush(post);
        return PostDetailResponse.from(post, java.util.List.of(), 0, false);
    }

    @Transactional
    public PostDetailResponse updatePost(String userId, String postId, UpdatePostRequest input) {
        Post post = postRepository.findById(postId).orElseThrow(() -> new NotFoundException("게시글을 찾을 수 없습니다."));
        if (!post.getAuthor().getId().equals(userId)) {
            throw new ForbiddenException("본인 게시글만 수정할 수 있습니다.");
        }
        post.setTitle(input.title());
        post.setContent(input.content());
        post.setCategory(input.category());
        post.setImageUrl(input.imageUrl());
        postRepository.saveAndFlush(post);

        var comments = commentRepository.findByPost_IdOrderByCreatedAtAsc(postId, Pageable.ofSize(50)).stream()
                .map(CommentResponse::from)
                .toList();
        long likeCount = likeRepository.countByPost_Id(postId);
        boolean likedByMe = likeRepository.findByPost_IdAndUser_Id(postId, userId).isPresent();
        return PostDetailResponse.from(post, comments, likeCount, likedByMe);
    }

    @Transactional
    public void deletePost(String userId, String postId) {
        Post post = postRepository.findById(postId).orElseThrow(() -> new NotFoundException("게시글을 찾을 수 없습니다."));
        if (!post.getAuthor().getId().equals(userId)) {
            throw new ForbiddenException("본인 게시글만 삭제할 수 있습니다.");
        }
        postRepository.delete(post);
    }

    @Transactional
    public CommentResponse addComment(String userId, String postId, CreateCommentRequest input) {
        Post post = postRepository.findById(postId).orElseThrow(() -> new NotFoundException("게시글을 찾을 수 없습니다."));
        User author = userRepository.findById(userId).orElseThrow(NotFoundException::new);

        Comment comment = new Comment();
        comment.setPost(post);
        comment.setAuthor(author);
        comment.setContent(input.content());
        commentRepository.saveAndFlush(comment);
        return CommentResponse.from(comment);
    }

    @Transactional
    public void deleteComment(String userId, String commentId) {
        Comment comment =
                commentRepository.findById(commentId).orElseThrow(() -> new NotFoundException("댓글을 찾을 수 없습니다."));
        if (!comment.getAuthor().getId().equals(userId)) {
            throw new ForbiddenException("본인 댓글만 삭제할 수 있습니다.");
        }
        commentRepository.delete(comment);
    }

    // 좋아요 추가는 동시 클릭 시 유니크 제약 경합이 날 수 있어, 이미 눌린 것으로 간주하고
    // 무시한다. 최종 liked/likeCount는 항상 다시 조회해 반환하므로 일관성이 깨지지 않는다.
    @Transactional
    public LikeToggleResponse toggleLike(String userId, String postId) {
        Post post = postRepository.findById(postId).orElseThrow(() -> new NotFoundException("게시글을 찾을 수 없습니다."));
        boolean existing = likeRepository.findByPost_IdAndUser_Id(postId, userId).isPresent();

        if (existing) {
            likeRepository.deleteByPost_IdAndUser_Id(postId, userId);
        } else {
            try {
                User user = userRepository.findById(userId).orElseThrow(NotFoundException::new);
                Like like = new Like();
                like.setPost(post);
                like.setUser(user);
                likeRepository.saveAndFlush(like);
            } catch (DataIntegrityViolationException ignored) {
                // 동시에 눌려 이미 좋아요가 반영된 상태 - 그대로 진행해 최신 상태를 조회한다.
            }
        }

        long likeCount = likeRepository.countByPost_Id(postId);
        boolean likedByMe = likeRepository.findByPost_IdAndUser_Id(postId, userId).isPresent();
        return new LikeToggleResponse(likedByMe, likeCount);
    }
}
