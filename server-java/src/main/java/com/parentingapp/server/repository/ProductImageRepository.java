package com.parentingapp.server.repository;

import com.parentingapp.server.domain.ProductImage;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductImageRepository extends JpaRepository<ProductImage, String> {
    void deleteByProduct_Id(String productId);
}
