package com.parentingapp.server.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record GoogleLoginRequest(@NotBlank(message = "구글 ID 토큰이 필요합니다.") String idToken) {}
