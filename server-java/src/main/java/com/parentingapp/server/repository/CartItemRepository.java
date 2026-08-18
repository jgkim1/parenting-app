package com.parentingapp.server.repository;

import com.parentingapp.server.domain.CartItem;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

public interface CartItemRepository extends JpaRepository<CartItem, String> {
    Optional<CartItem> findByCart_IdAndProduct_Id(String cartId, String productId);

    List<CartItem> findByCart_Id(String cartId);

    @Transactional
    void deleteByCart_IdAndProduct_Id(String cartId, String productId);

    @Transactional
    void deleteByCart_Id(String cartId);
}
