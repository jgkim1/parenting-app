package com.parentingapp.server.cart;

import com.parentingapp.server.cart.dto.AddCartItemRequest;
import com.parentingapp.server.cart.dto.CartItemResponse;
import com.parentingapp.server.cart.dto.CartResponse;
import com.parentingapp.server.cart.dto.UpdateCartItemRequest;
import com.parentingapp.server.common.exception.BadRequestException;
import com.parentingapp.server.common.exception.NotFoundException;
import com.parentingapp.server.domain.Cart;
import com.parentingapp.server.domain.CartItem;
import com.parentingapp.server.domain.Product;
import com.parentingapp.server.domain.User;
import com.parentingapp.server.repository.CartItemRepository;
import com.parentingapp.server.repository.CartRepository;
import com.parentingapp.server.repository.ProductRepository;
import com.parentingapp.server.repository.UserRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    public CartService(
            CartRepository cartRepository,
            CartItemRepository cartItemRepository,
            ProductRepository productRepository,
            UserRepository userRepository) {
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
        this.userRepository = userRepository;
    }

    // userId에 유니크 제약이 걸려 있어, 같은 사용자의 요청 두 개가 동시에 들어오면 경합하다
    // 한쪽이 유니크 제약 위반으로 실패할 수 있다. 이 경우는 이미 다른 요청이 카트를
    // 만들어준 것이므로 재조회로 복구한다.
    private Cart getOrCreateCart(String userId) {
        return cartRepository.findByUser_Id(userId).orElseGet(() -> {
            try {
                User user = userRepository.findById(userId).orElseThrow(NotFoundException::new);
                Cart cart = new Cart();
                cart.setUser(user);
                return cartRepository.saveAndFlush(cart);
            } catch (DataIntegrityViolationException e) {
                return cartRepository.findByUser_Id(userId).orElseThrow();
            }
        });
    }

    @Transactional
    public CartResponse getCart(String userId) {
        Cart cart = getOrCreateCart(userId);
        return buildResponse(cart);
    }

    @Transactional
    public CartResponse addItem(String userId, AddCartItemRequest input) {
        Product product = productRepository.findById(input.productId()).orElse(null);
        if (product == null || !product.isActive()) {
            throw new NotFoundException("상품을 찾을 수 없습니다.");
        }

        Cart cart = getOrCreateCart(userId);
        CartItem existing = cartItemRepository.findByCart_IdAndProduct_Id(cart.getId(), product.getId()).orElse(null);
        int nextQuantity = (existing != null ? existing.getQuantity() : 0) + input.quantity();
        if (nextQuantity > product.getStock()) {
            throw new BadRequestException("재고가 부족합니다. (재고 " + product.getStock() + "개)");
        }

        if (existing != null) {
            existing.setQuantity(nextQuantity);
            cartItemRepository.save(existing);
        } else {
            CartItem item = new CartItem();
            item.setCart(cart);
            item.setProduct(product);
            item.setQuantity(nextQuantity);
            cartItemRepository.save(item);
        }

        return buildResponse(cart);
    }

    @Transactional
    public CartResponse updateItem(String userId, String productId, UpdateCartItemRequest input) {
        Cart cart = getOrCreateCart(userId);
        CartItem item = cartItemRepository
                .findByCart_IdAndProduct_Id(cart.getId(), productId)
                .orElseThrow(() -> new NotFoundException("장바구니에 없는 상품입니다."));
        if (input.quantity() > item.getProduct().getStock()) {
            throw new BadRequestException("재고가 부족합니다. (재고 " + item.getProduct().getStock() + "개)");
        }
        item.setQuantity(input.quantity());
        cartItemRepository.save(item);
        return buildResponse(cart);
    }

    @Transactional
    public CartResponse removeItem(String userId, String productId) {
        Cart cart = getOrCreateCart(userId);
        cartItemRepository.deleteByCart_IdAndProduct_Id(cart.getId(), productId);
        return buildResponse(cart);
    }

    private CartResponse buildResponse(Cart cart) {
        var items = cartItemRepository.findByCart_Id(cart.getId()).stream().map(CartItemResponse::from).toList();
        return CartResponse.from(cart, items);
    }
}
