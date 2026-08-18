package com.parentingapp.server.ad.dto;

import com.parentingapp.server.domain.Ad;
import com.parentingapp.server.domain.AdPlacement;
import java.time.LocalDateTime;

public record AdResponse(
        String id,
        AdPlacement placement,
        String title,
        String imageUrl,
        String linkUrl,
        boolean isActive,
        Integer sortOrder,
        LocalDateTime createdAt,
        LocalDateTime updatedAt) {

    public static AdResponse from(Ad ad) {
        return new AdResponse(
                ad.getId(),
                ad.getPlacement(),
                ad.getTitle(),
                ad.getImageUrl(),
                ad.getLinkUrl(),
                ad.isActive(),
                ad.getSortOrder(),
                ad.getCreatedAt(),
                ad.getUpdatedAt());
    }
}
