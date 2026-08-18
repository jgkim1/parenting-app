package com.parentingapp.server.product.dto;

import com.parentingapp.server.domain.Product;
import java.time.LocalDateTime;
import java.util.List;

public record ProductSummaryResponse(
        String id,
        String name,
        String description,
        Integer price,
        Integer stock,
        boolean isActive,
        CategoryResponse category,
        List<ProductImageResponse> images,
        LocalDateTime createdAt,
        LocalDateTime updatedAt) {

    public static ProductSummaryResponse from(Product product) {
        return new ProductSummaryResponse(
                product.getId(),
                product.getName(),
                product.getDescription(),
                product.getPrice(),
                product.getStock(),
                product.isActive(),
                CategoryResponse.from(product.getCategory()),
                product.getImages().stream().map(ProductImageResponse::from).toList(),
                product.getCreatedAt(),
                product.getUpdatedAt());
    }
}
