package com.parentingapp.server.auth.dto;

import com.parentingapp.server.domain.AuthProvider;
import com.parentingapp.server.domain.User;
import com.parentingapp.server.domain.UserRole;
import java.time.LocalDateTime;

// passwordHash를 뺀 안전한 사용자 응답. Node의 toSafeUser와 동일한 역할.
public record UserResponse(
        String id,
        String email,
        String nickname,
        UserRole role,
        AuthProvider provider,
        String providerId,
        LocalDateTime createdAt,
        LocalDateTime updatedAt) {

    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getNickname(),
                user.getRole(),
                user.getProvider(),
                user.getProviderId(),
                user.getCreatedAt(),
                user.getUpdatedAt());
    }
}
