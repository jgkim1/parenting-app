package com.parentingapp.server.order.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateOrderRequest(@NotBlank(message = "배송지를 입력해주세요.") @Size(max = 300) String shippingAddr) {}
