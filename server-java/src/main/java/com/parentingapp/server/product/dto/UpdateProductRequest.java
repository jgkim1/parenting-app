package com.parentingapp.server.product.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import java.util.List;

public record UpdateProductRequest(
        String categoryId,
        @Size(max = 200) String name,
        String description,
        @Min(value = 0, message = "가격은 0 이상이어야 합니다.") Integer price,
        @Min(value = 0, message = "재고는 0 이상이어야 합니다.") Integer stock,
        @Size(max = 10, message = "이미지는 최대 10장까지 등록할 수 있습니다.") List<String> imageUrls,
        Boolean isActive) {}
