package com.parentingapp.server.community.dto;

import com.parentingapp.server.domain.Comment;
import java.time.LocalDateTime;

public record CommentResponse(String id, String postId, String authorId, String content, LocalDateTime createdAt, PostAuthorResponse author) {
    public static CommentResponse from(Comment comment) {
        return new CommentResponse(
                comment.getId(),
                comment.getPost().getId(),
                comment.getAuthor().getId(),
                comment.getContent(),
                comment.getCreatedAt(),
                PostAuthorResponse.from(comment.getAuthor()));
    }
}
