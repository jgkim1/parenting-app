package com.parentingapp.server.cart.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record AddCartItemRequest(
        @NotBlank(message = "올바른 상품이 아닙니다.") String productId,
        @Min(value = 1, message = "수량은 1 이상이어야 합니다.") Integer quantity) {

    public AddCartItemRequest {
        if (quantity == null) quantity = 1;
    }
}
