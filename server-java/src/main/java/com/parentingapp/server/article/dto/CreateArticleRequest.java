package com.parentingapp.server.article.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateArticleRequest(
        @NotBlank(message = "올바른 카테고리가 아닙니다.") String categoryId,
        @NotBlank(message = "제목을 입력해주세요.") @Size(max = 200) String title,
        @NotBlank(message = "본문을 입력해주세요.") String content,
        String thumbnailUrl) {}
