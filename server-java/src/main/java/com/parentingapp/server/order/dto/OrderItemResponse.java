package com.parentingapp.server.order.dto;

import com.parentingapp.server.domain.OrderItem;
import com.parentingapp.server.product.dto.ProductSummaryResponse;

public record OrderItemResponse(
        String id, String orderId, String productId, Integer quantity, Integer priceAtOrder, ProductSummaryResponse product) {
    public static OrderItemResponse from(OrderItem item) {
        return new OrderItemResponse(
                item.getId(),
                item.getOrder().getId(),
                item.getProduct().getId(),
                item.getQuantity(),
                item.getPriceAtOrder(),
                ProductSummaryResponse.from(item.getProduct()));
    }
}
