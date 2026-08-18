package com.parentingapp.server.product.dto;

import com.parentingapp.server.domain.Product;
import com.parentingapp.server.domain.Review;
import java.time.LocalDateTime;
import java.util.List;

public record ProductDetailResponse(
        String id,
        String name,
        String description,
        Integer price,
        Integer stock,
        boolean isActive,
        CategoryResponse category,
        SellerResponse seller,
        List<ProductImageResponse> images,
        List<ProductReviewResponse> reviews,
        ReviewStatsResponse reviewStats,
        LocalDateTime createdAt,
        LocalDateTime updatedAt) {

    public static ProductDetailResponse from(Product product, List<Review> reviews, ReviewStatsResponse stats) {
        return new ProductDetailResponse(
                product.getId(),
                product.getName(),
                product.getDescription(),
                product.getPrice(),
                product.getStock(),
                product.isActive(),
                CategoryResponse.from(product.getCategory()),
                SellerResponse.from(product.getSeller()),
                product.getImages().stream().map(ProductImageResponse::from).toList(),
                reviews.stream().map(ProductReviewResponse::from).toList(),
                stats,
                product.getCreatedAt(),
                product.getUpdatedAt());
    }
}
