package com.parentingapp.server.product.dto;

import com.parentingapp.server.domain.Category;

public record CategoryResponse(String id, String name, String slug) {
    public static CategoryResponse from(Category category) {
        return new CategoryResponse(category.getId(), category.getName(), category.getSlug());
    }
}
