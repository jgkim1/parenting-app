package com.parentingapp.server.product.dto;

import com.parentingapp.server.domain.User;

public record ReviewUserResponse(String id, String nickname) {
    public static ReviewUserResponse from(User user) {
        return new ReviewUserResponse(user.getId(), user.getNickname());
    }
}
