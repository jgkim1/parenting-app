package com.parentingapp.server.community;

import com.parentingapp.server.common.dto.PageResponse;
import com.parentingapp.server.common.security.AuthenticatedUser;
import com.parentingapp.server.community.dto.CommentResponse;
import com.parentingapp.server.community.dto.CreateCommentRequest;
import com.parentingapp.server.community.dto.CreatePostRequest;
import com.parentingapp.server.community.dto.LikeToggleResponse;
import com.parentingapp.server.community.dto.PostDetailResponse;
import com.parentingapp.server.community.dto.PostSummaryResponse;
import com.parentingapp.server.community.dto.UpdatePostRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/posts")
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @GetMapping
    public PageResponse<PostSummaryResponse> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String q) {
        return postService.listPosts(page, pageSize, category, q);
    }

    @GetMapping("/{id}")
    public PostDetailResponse get(@AuthenticationPrincipal AuthenticatedUser currentUser, @PathVariable String id) {
        return postService.getPostById(id, currentUser != null ? currentUser.id() : null);
    }

    @PostMapping
    public ResponseEntity<PostDetailResponse> create(
            @AuthenticationPrincipal AuthenticatedUser currentUser, @Valid @RequestBody CreatePostRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(postService.createPost(currentUser.id(), request));
    }

    @PatchMapping("/{id}")
    public PostDetailResponse update(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @PathVariable String id,
            @Valid @RequestBody UpdatePostRequest request) {
        return postService.updatePost(currentUser.id(), id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal AuthenticatedUser currentUser, @PathVariable String id) {
        postService.deletePost(currentUser.id(), id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/comments")
    public ResponseEntity<CommentResponse> addComment(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @PathVariable String id,
            @Valid @RequestBody CreateCommentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(postService.addComment(currentUser.id(), id, request));
    }

    @PostMapping("/{id}/like")
    public LikeToggleResponse toggleLike(@AuthenticationPrincipal AuthenticatedUser currentUser, @PathVariable String id) {
        return postService.toggleLike(currentUser.id(), id);
    }
}
