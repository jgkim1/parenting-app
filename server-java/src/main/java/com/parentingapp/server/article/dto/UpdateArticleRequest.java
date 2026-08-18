package com.parentingapp.server.article.dto;

import jakarta.validation.constraints.Size;

public record UpdateArticleRequest(
        String categoryId, @Size(max = 200) String title, String content, String thumbnailUrl, Boolean isActive) {}
