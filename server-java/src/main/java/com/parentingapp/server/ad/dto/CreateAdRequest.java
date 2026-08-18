package com.parentingapp.server.ad.dto;

import com.parentingapp.server.domain.AdPlacement;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateAdRequest(
        @NotNull(message = "올바른 삽입 위치가 아닙니다.") AdPlacement placement,
        @NotBlank(message = "광고 제목을 입력해주세요.") @Size(max = 100) String title,
        @NotBlank(message = "올바른 이미지 URL이 아닙니다.") String imageUrl,
        String linkUrl,
        Integer sortOrder) {

    public CreateAdRequest {
        if (sortOrder == null) sortOrder = 0;
    }
}
