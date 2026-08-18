package com.parentingapp.server.community.dto;

import com.parentingapp.server.domain.Post;
import java.time.LocalDateTime;
import java.util.List;

public record PostDetailResponse(
        String id,
        String title,
        String content,
        String category,
        String imageUrl,
        Integer viewCount,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        PostAuthorResponse author,
        List<CommentResponse> comments,
        long likeCount,
        boolean likedByMe) {

    public static PostDetailResponse from(Post post, List<CommentResponse> comments, long likeCount, boolean likedByMe) {
        return new PostDetailResponse(
                post.getId(),
                post.getTitle(),
                post.getContent(),
                post.getCategory(),
                post.getImageUrl(),
                post.getViewCount(),
                post.getCreatedAt(),
                post.getUpdatedAt(),
                PostAuthorResponse.from(post.getAuthor()),
                comments,
                likeCount,
                likedByMe);
    }
}
