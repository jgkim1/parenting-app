package com.parentingapp.server.cart;

import com.parentingapp.server.cart.dto.AddCartItemRequest;
import com.parentingapp.server.cart.dto.CartResponse;
import com.parentingapp.server.cart.dto.UpdateCartItemRequest;
import com.parentingapp.server.common.security.AuthenticatedUser;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/cart")
public class CartController {

    private final CartService cartService;

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    @GetMapping
    public CartResponse get(@AuthenticationPrincipal AuthenticatedUser currentUser) {
        return cartService.getCart(currentUser.id());
    }

    @PostMapping("/items")
    public CartResponse addItem(
            @AuthenticationPrincipal AuthenticatedUser currentUser, @Valid @RequestBody AddCartItemRequest request) {
        return cartService.addItem(currentUser.id(), request);
    }

    @PatchMapping("/items/{productId}")
    public CartResponse updateItem(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @PathVariable String productId,
            @Valid @RequestBody UpdateCartItemRequest request) {
        return cartService.updateItem(currentUser.id(), productId, request);
    }

    @DeleteMapping("/items/{productId}")
    public CartResponse removeItem(@AuthenticationPrincipal AuthenticatedUser currentUser, @PathVariable String productId) {
        return cartService.removeItem(currentUser.id(), productId);
    }
}
