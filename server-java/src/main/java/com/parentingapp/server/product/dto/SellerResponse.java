package com.parentingapp.server.product.dto;

import com.parentingapp.server.domain.User;

public record SellerResponse(String id, String nickname) {
    public static SellerResponse from(User user) {
        return new SellerResponse(user.getId(), user.getNickname());
    }
}
