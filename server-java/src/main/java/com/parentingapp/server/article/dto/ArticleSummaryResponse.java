package com.parentingapp.server.article.dto;

import com.parentingapp.server.domain.Article;
import java.time.LocalDateTime;

public record ArticleSummaryResponse(
        String id,
        String title,
        String thumbnailUrl,
        boolean isActive,
        Integer viewCount,
        ArticleCategoryResponse category,
        LocalDateTime createdAt) {

    public static ArticleSummaryResponse from(Article article) {
        return new ArticleSummaryResponse(
                article.getId(),
                article.getTitle(),
                article.getThumbnailUrl(),
                article.isActive(),
                article.getViewCount(),
                ArticleCategoryResponse.from(article.getCategory()),
                article.getCreatedAt());
    }
}
