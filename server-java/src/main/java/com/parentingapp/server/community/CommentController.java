package com.parentingapp.server.community;

import com.parentingapp.server.common.security.AuthenticatedUser;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/comments")
public class CommentController {

    private final PostService postService;

    public CommentController(PostService postService) {
        this.postService = postService;
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal AuthenticatedUser currentUser, @PathVariable String id) {
        postService.deleteComment(currentUser.id(), id);
        return ResponseEntity.noContent().build();
    }
}
