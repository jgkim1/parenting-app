package com.parentingapp.server.child.dto;

import com.parentingapp.server.domain.Child;
import com.parentingapp.server.domain.ChildGender;
import java.time.LocalDateTime;

public record ChildResponse(
        String id, String userId, String nickname, ChildGender gender, LocalDateTime birthDate, LocalDateTime createdAt) {
    public static ChildResponse from(Child child) {
        return new ChildResponse(
                child.getId(),
                child.getUser().getId(),
                child.getNickname(),
                child.getGender(),
                child.getBirthDate(),
                child.getCreatedAt());
    }
}
