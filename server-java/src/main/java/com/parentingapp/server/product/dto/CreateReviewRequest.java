package com.parentingapp.server.product.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateReviewRequest(
        @NotNull(message = "평점을 입력해주세요.")
                @Min(value = 1, message = "평점은 1~5 사이여야 합니다.")
                @Max(value = 5, message = "평점은 1~5 사이여야 합니다.")
                Integer rating,
        @NotBlank(message = "리뷰 내용을 입력해주세요.") @Size(max = 1000) String content) {}
