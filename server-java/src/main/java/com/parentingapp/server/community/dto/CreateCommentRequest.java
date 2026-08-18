package com.parentingapp.server.community.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateCommentRequest(@NotBlank(message = "댓글 내용을 입력해주세요.") @Size(max = 1000) String content) {}
