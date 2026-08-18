package com.parentingapp.server.order;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.parentingapp.server.IntegrationTestBase;
import com.parentingapp.server.domain.Category;
import com.parentingapp.server.domain.Product;
import com.parentingapp.server.domain.UserRole;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

class OrderControllerTest extends IntegrationTestBase {

    @Test
    void 재고보다_많이_담으면_400을_반환한다() throws Exception {
        SignedUpUser seller = signUpWithRole(UserRole.SELLER);
        SignedUpUser customer = signUpUser();
        Category category = createCategory();
        Product product = createProduct(seller.userId(), category.getId()); // 재고 10

        mockMvc.perform(post("/api/cart/items")
                        .header("Authorization", authHeader(customer.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("productId", product.getId(), "quantity", 11))))
                .andExpect(status().isBadRequest());
    }

    @Test
    void 주문하면_재고가_차감되고_장바구니가_비워진다() throws Exception {
        SignedUpUser seller = signUpWithRole(UserRole.SELLER);
        SignedUpUser customer = signUpUser();
        Category category = createCategory();
        Product product = createProduct(seller.userId(), category.getId()); // 재고 10

        mockMvc.perform(post("/api/cart/items")
                        .header("Authorization", authHeader(customer.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("productId", product.getId(), "quantity", 3))))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/orders")
                        .header("Authorization", authHeader(customer.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("shippingAddr", "서울시 어딘가 123"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.totalAmount").value(30000))
                .andExpect(jsonPath("$.items.length()").value(1));

        // 재고가 실제로 줄었는지 확인
        mockMvc.perform(get("/api/products/" + product.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.stock").value(7));

        // 장바구니가 비워졌는지 확인
        mockMvc.perform(get("/api/cart").header("Authorization", authHeader(customer.accessToken())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(0));
    }

    @Test
    void 장바구니가_비어있으면_주문을_생성할_수_없다() throws Exception {
        SignedUpUser customer = signUpUser();
        mockMvc.perform(post("/api/orders")
                        .header("Authorization", authHeader(customer.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("shippingAddr", "서울시 어딘가 123"))))
                .andExpect(status().isBadRequest());
    }

    @Test
    void 다른_사람의_주문은_조회할_수_없다() throws Exception {
        SignedUpUser seller = signUpWithRole(UserRole.SELLER);
        SignedUpUser customer = signUpUser();
        SignedUpUser stranger = signUpUser();
        Category category = createCategory();
        Product product = createProduct(seller.userId(), category.getId());

        mockMvc.perform(post("/api/cart/items")
                .header("Authorization", authHeader(customer.accessToken()))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("productId", product.getId(), "quantity", 1))));

        String orderBody = mockMvc.perform(post("/api/orders")
                        .header("Authorization", authHeader(customer.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("shippingAddr", "서울시 어딘가 123"))))
                .andReturn()
                .getResponse()
                .getContentAsString();
        String orderId = objectMapper.readTree(orderBody).get("id").asText();

        mockMvc.perform(get("/api/orders/" + orderId).header("Authorization", authHeader(stranger.accessToken())))
                .andExpect(status().isNotFound());
    }
}
