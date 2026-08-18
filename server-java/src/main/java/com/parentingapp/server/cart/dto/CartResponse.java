package com.parentingapp.server.cart.dto;

import com.parentingapp.server.domain.Cart;
import java.util.List;

public record CartResponse(String id, String userId, List<CartItemResponse> items) {
    public static CartResponse from(Cart cart, List<CartItemResponse> items) {
        return new CartResponse(cart.getId(), cart.getUser().getId(), items);
    }
}
