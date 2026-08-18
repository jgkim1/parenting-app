package com.parentingapp.server.order;

import com.parentingapp.server.common.dto.PageResponse;
import com.parentingapp.server.common.exception.BadRequestException;
import com.parentingapp.server.common.exception.NotFoundException;
import com.parentingapp.server.domain.Cart;
import com.parentingapp.server.domain.CartItem;
import com.parentingapp.server.domain.Order;
import com.parentingapp.server.domain.OrderItem;
import com.parentingapp.server.domain.Product;
import com.parentingapp.server.domain.User;
import com.parentingapp.server.order.dto.CreateOrderRequest;
import com.parentingapp.server.order.dto.OrderResponse;
import com.parentingapp.server.repository.CartItemRepository;
import com.parentingapp.server.repository.CartRepository;
import com.parentingapp.server.repository.OrderRepository;
import com.parentingapp.server.repository.ProductRepository;
import com.parentingapp.server.repository.UserRepository;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    public OrderService(
            CartRepository cartRepository,
            CartItemRepository cartItemRepository,
            OrderRepository orderRepository,
            ProductRepository productRepository,
            UserRepository userRepository) {
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.orderRepository = orderRepository;
        this.productRepository = productRepository;
        this.userRepository = userRepository;
    }

    // 장바구니 내용을 스냅샷하여 주문을 생성한다. 재고 검증, 재고 차감, 장바구니 비우기를
    // 하나의 트랜잭션으로 묶어 중간에 실패해도 일부만 반영되지 않도록 한다.
    @Transactional
    public OrderResponse createOrder(String userId, CreateOrderRequest input) {
        Cart cart = cartRepository.findByUser_Id(userId).orElse(null);
        List<CartItem> items = cart != null ? cartItemRepository.findByCart_Id(cart.getId()) : List.of();
        if (cart == null || items.isEmpty()) {
            throw new BadRequestException("장바구니가 비어 있습니다.");
        }

        int totalAmount = 0;
        for (CartItem item : items) {
            Product product = item.getProduct();
            if (!product.isActive()) {
                throw new BadRequestException("판매가 중지된 상품이 포함되어 있습니다: " + product.getName());
            }
            if (item.getQuantity() > product.getStock()) {
                throw new BadRequestException("재고가 부족합니다: " + product.getName() + " (재고 " + product.getStock() + "개)");
            }
            totalAmount += product.getPrice() * item.getQuantity();
        }

        User user = userRepository.findById(userId).orElseThrow(NotFoundException::new);
        Order order = new Order();
        order.setUser(user);
        order.setTotalAmount(totalAmount);
        order.setShippingAddr(input.shippingAddr());
        orderRepository.saveAndFlush(order);

        for (CartItem item : items) {
            OrderItem orderItem = new OrderItem();
            orderItem.setOrder(order);
            orderItem.setProduct(item.getProduct());
            orderItem.setQuantity(item.getQuantity());
            orderItem.setPriceAtOrder(item.getProduct().getPrice());
            order.getItems().add(orderItem);

            Product product = item.getProduct();
            product.setStock(product.getStock() - item.getQuantity());
            productRepository.save(product);
        }
        orderRepository.saveAndFlush(order);

        cartItemRepository.deleteByCart_Id(cart.getId());

        return OrderResponse.from(order);
    }

    @Transactional(readOnly = true)
    public PageResponse<OrderResponse> listOrders(String userId, int page, int pageSize) {
        Page<Order> result =
                orderRepository.findByUser_IdOrderByCreatedAtDesc(userId, PageRequest.of(page - 1, pageSize, Sort.unsorted()));
        return PageResponse.of(result.map(OrderResponse::from), page, pageSize);
    }

    @Transactional(readOnly = true)
    public OrderResponse getOrderById(String userId, String id) {
        Order order =
                orderRepository.findByIdAndUser_Id(id, userId).orElseThrow(() -> new NotFoundException("주문을 찾을 수 없습니다."));
        return OrderResponse.from(order);
    }
}
