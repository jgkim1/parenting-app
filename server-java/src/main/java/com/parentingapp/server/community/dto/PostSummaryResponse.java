package com.parentingapp.server.community.dto;

import com.parentingapp.server.domain.Post;
import java.time.LocalDateTime;

public record PostSummaryResponse(
        String id,
        String title,
        String category,
        String imageUrl,
        Integer viewCount,
        LocalDateTime createdAt,
        PostAuthorResponse author,
        CountResponse _count) {

    public static PostSummaryResponse from(Post post, long commentCount, long likeCount) {
        return new PostSummaryResponse(
                post.getId(),
                post.getTitle(),
                post.getCategory(),
                post.getImageUrl(),
                post.getViewCount(),
                post.getCreatedAt(),
                PostAuthorResponse.from(post.getAuthor()),
                new CountResponse(commentCount, likeCount));
    }
}
