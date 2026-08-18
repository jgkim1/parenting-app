package com.parentingapp.server.order;

import com.parentingapp.server.common.dto.PageResponse;
import com.parentingapp.server.common.security.AuthenticatedUser;
import com.parentingapp.server.order.dto.CreateOrderRequest;
import com.parentingapp.server.order.dto.OrderResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping
    public PageResponse<OrderResponse> list(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        return orderService.listOrders(currentUser.id(), page, pageSize);
    }

    @GetMapping("/{id}")
    public OrderResponse get(@AuthenticationPrincipal AuthenticatedUser currentUser, @PathVariable String id) {
        return orderService.getOrderById(currentUser.id(), id);
    }

    @PostMapping
    public ResponseEntity<OrderResponse> create(
            @AuthenticationPrincipal AuthenticatedUser currentUser, @Valid @RequestBody CreateOrderRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(orderService.createOrder(currentUser.id(), request));
    }
}
