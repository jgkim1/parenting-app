package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Order;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<Order, String> {
    Page<Order> findByUser_IdOrderByCreatedAtDesc(String userId, Pageable pageable);

    Optional<Order> findByIdAndUser_Id(String id, String userId);
}
