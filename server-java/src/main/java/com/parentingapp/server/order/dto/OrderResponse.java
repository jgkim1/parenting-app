package com.parentingapp.server.order.dto;

import com.parentingapp.server.domain.Order;
import com.parentingapp.server.domain.OrderStatus;
import java.time.LocalDateTime;
import java.util.List;

public record OrderResponse(
        String id,
        String userId,
        OrderStatus status,
        Integer totalAmount,
        String shippingAddr,
        List<OrderItemResponse> items,
        LocalDateTime createdAt,
        LocalDateTime updatedAt) {

    public static OrderResponse from(Order order) {
        return new OrderResponse(
                order.getId(),
                order.getUser().getId(),
                order.getStatus(),
                order.getTotalAmount(),
                order.getShippingAddr(),
                order.getItems().stream().map(OrderItemResponse::from).toList(),
                order.getCreatedAt(),
                order.getUpdatedAt());
    }
}
