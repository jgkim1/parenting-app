package com.parentingapp.server.article.dto;

import com.parentingapp.server.domain.ArticleCategory;

public record ArticleCategoryResponse(String id, String name, String slug) {
    public static ArticleCategoryResponse from(ArticleCategory category) {
        return new ArticleCategoryResponse(category.getId(), category.getName(), category.getSlug());
    }
}
