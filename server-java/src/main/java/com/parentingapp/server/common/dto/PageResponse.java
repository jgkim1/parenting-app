package com.parentingapp.server.common.dto;

import java.util.List;
import org.springframework.data.domain.Page;

// Node 쪽 페이지네이션 응답({items, page, pageSize, total, totalPages})과 동일한 형태.
public record PageResponse<T>(List<T> items, int page, int pageSize, long total, int totalPages) {

    public static <T> PageResponse<T> of(Page<T> page, int pageNumber, int pageSize) {
        return new PageResponse<>(
                page.getContent(),
                pageNumber,
                pageSize,
                page.getTotalElements(),
                Math.max(1, page.getTotalPages()));
    }
}
