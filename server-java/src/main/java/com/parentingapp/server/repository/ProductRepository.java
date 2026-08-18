package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductRepository extends JpaRepository<Product, String> {

    @Query(
            "select p from Product p where"
                    + " (:active is null or p.active = :active)"
                    + " and (:categoryId is null or p.category.id = :categoryId)"
                    + " and (:q is null or lower(p.name) like lower(concat('%', :q, '%')))")
    Page<Product> search(
            @Param("active") Boolean active,
            @Param("categoryId") String categoryId,
            @Param("q") String q,
            Pageable pageable);
}
