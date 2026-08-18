package com.parentingapp.server.article.dto;

import com.parentingapp.server.domain.User;

public record ArticleAuthorResponse(String id, String nickname) {
    public static ArticleAuthorResponse from(User user) {
        return new ArticleAuthorResponse(user.getId(), user.getNickname());
    }
}
