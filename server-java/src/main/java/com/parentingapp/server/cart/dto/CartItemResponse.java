package com.parentingapp.server.cart.dto;

import com.parentingapp.server.domain.CartItem;
import com.parentingapp.server.product.dto.ProductSummaryResponse;

public record CartItemResponse(String id, String cartId, String productId, Integer quantity, ProductSummaryResponse product) {
    public static CartItemResponse from(CartItem item) {
        return new CartItemResponse(
                item.getId(),
                item.getCart().getId(),
                item.getProduct().getId(),
                item.getQuantity(),
                ProductSummaryResponse.from(item.getProduct()));
    }
}
