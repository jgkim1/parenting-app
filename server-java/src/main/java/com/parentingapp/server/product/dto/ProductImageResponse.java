package com.parentingapp.server.product.dto;

import com.parentingapp.server.domain.ProductImage;

public record ProductImageResponse(String id, String url, Integer sortOrder) {
    public static ProductImageResponse from(ProductImage image) {
        return new ProductImageResponse(image.getId(), image.getUrl(), image.getSortOrder());
    }
}
