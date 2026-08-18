package com.parentingapp.server.product.dto;

import com.parentingapp.server.domain.Review;
import java.time.LocalDateTime;

public record ProductReviewResponse(
        String id, String productId, String userId, Integer rating, String content, LocalDateTime createdAt, ReviewUserResponse user) {

    public static ProductReviewResponse from(Review review) {
        return new ProductReviewResponse(
                review.getId(),
                review.getProduct().getId(),
                review.getUser().getId(),
                review.getRating(),
                review.getContent(),
                review.getCreatedAt(),
                ReviewUserResponse.from(review.getUser()));
    }
}
