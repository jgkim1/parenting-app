package com.parentingapp.server.article.dto;

import com.parentingapp.server.domain.Article;
import java.time.LocalDateTime;

public record ArticleDetailResponse(
        String id,
        String title,
        String content,
        String thumbnailUrl,
        ArticleCategoryResponse category,
        ArticleAuthorResponse author,
        boolean isActive,
        Integer viewCount,
        LocalDateTime createdAt,
        LocalDateTime updatedAt) {

    public static ArticleDetailResponse from(Article article) {
        return new ArticleDetailResponse(
                article.getId(),
                article.getTitle(),
                article.getContent(),
                article.getThumbnailUrl(),
                ArticleCategoryResponse.from(article.getCategory()),
                ArticleAuthorResponse.from(article.getAuthor()),
                article.isActive(),
                article.getViewCount(),
                article.getCreatedAt(),
                article.getUpdatedAt());
    }
}
