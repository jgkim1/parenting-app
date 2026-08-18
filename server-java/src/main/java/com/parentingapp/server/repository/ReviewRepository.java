package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Review;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ReviewRepository extends JpaRepository<Review, String> {
    Optional<Review> findByProduct_IdAndUser_Id(String productId, String userId);

    List<Review> findByProduct_IdOrderByCreatedAtDesc(String productId);

    long countByProduct_Id(String productId);

    @Query("select coalesce(avg(r.rating), 0) from Review r where r.product.id = :productId")
    Double averageRatingByProductId(@Param("productId") String productId);
}
