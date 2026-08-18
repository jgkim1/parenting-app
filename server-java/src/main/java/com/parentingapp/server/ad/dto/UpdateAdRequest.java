package com.parentingapp.server.ad.dto;

import com.parentingapp.server.domain.AdPlacement;
import jakarta.validation.constraints.Size;

public record UpdateAdRequest(
        AdPlacement placement,
        @Size(max = 100) String title,
        String imageUrl,
        String linkUrl,
        Integer sortOrder,
        Boolean isActive) {}
