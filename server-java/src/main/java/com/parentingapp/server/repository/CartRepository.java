package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Cart;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CartRepository extends JpaRepository<Cart, String> {
    Optional<Cart> findByUser_Id(String userId);
}
