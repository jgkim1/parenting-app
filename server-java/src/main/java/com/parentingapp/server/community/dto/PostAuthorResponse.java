package com.parentingapp.server.community.dto;

import com.parentingapp.server.domain.User;

public record PostAuthorResponse(String id, String nickname) {
    public static PostAuthorResponse from(User user) {
        return new PostAuthorResponse(user.getId(), user.getNickname());
    }
}
