package com.parentingapp.server.child.dto;

import com.parentingapp.server.domain.ChildGender;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

public record CreateChildRequest(
        @NotBlank(message = "이름(애칭)을 입력해주세요.") @Size(max = 30) String nickname,
        ChildGender gender,
        @NotNull(message = "생년월일을 올바르게 입력해주세요.") LocalDateTime birthDate) {}
