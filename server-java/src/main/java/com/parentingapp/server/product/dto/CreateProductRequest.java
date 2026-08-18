package com.parentingapp.server.product.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record CreateProductRequest(
        @NotBlank(message = "올바른 카테고리가 아닙니다.") String categoryId,
        @NotBlank(message = "상품명을 입력해주세요.") @Size(max = 200) String name,
        @NotBlank(message = "상품 설명을 입력해주세요.") String description,
        @NotNull(message = "가격을 입력해주세요.") @Min(value = 0, message = "가격은 0 이상이어야 합니다.") Integer price,
        @Min(value = 0, message = "재고는 0 이상이어야 합니다.") Integer stock,
        @Size(max = 10, message = "이미지는 최대 10장까지 등록할 수 있습니다.") List<String> imageUrls) {

    public CreateProductRequest {
        if (stock == null) stock = 0;
        if (imageUrls == null) imageUrls = List.of();
    }
}
