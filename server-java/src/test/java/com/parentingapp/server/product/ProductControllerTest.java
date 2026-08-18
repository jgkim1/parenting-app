package com.parentingapp.server.product;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
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

class ProductControllerTest extends IntegrationTestBase {

    @Test
    void CUSTOMER는_상품을_등록할_수_없다() throws Exception {
        SignedUpUser customer = signUpUser();
        Category category = createCategory();

        mockMvc.perform(post("/api/products")
                        .header("Authorization", authHeader(customer.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "categoryId", category.getId(),
                                "name", "새 상품",
                                "description", "설명",
                                "price", 5000,
                                "stock", 3))))
                .andExpect(status().isForbidden());
    }

    @Test
    void SELLER는_상품을_등록할_수_있다() throws Exception {
        SignedUpUser seller = signUpWithRole(UserRole.SELLER);
        Category category = createCategory();

        mockMvc.perform(post("/api/products")
                        .header("Authorization", authHeader(seller.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "categoryId", category.getId(),
                                "name", "새 상품",
                                "description", "설명",
                                "price", 5000,
                                "stock", 3))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("새 상품"));
    }

    @Test
    void 다른_SELLER의_상품은_수정할_수_없고_ADMIN은_수정할_수_있다() throws Exception {
        SignedUpUser owner = signUpWithRole(UserRole.SELLER);
        SignedUpUser stranger = signUpWithRole(UserRole.SELLER);
        SignedUpUser admin = signUpWithRole(UserRole.ADMIN);
        Category category = createCategory();
        Product product = createProduct(owner.userId(), category.getId());

        mockMvc.perform(patch("/api/products/" + product.getId())
                        .header("Authorization", authHeader(stranger.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("name", "가로채기 시도"))))
                .andExpect(status().isForbidden());

        mockMvc.perform(patch("/api/products/" + product.getId())
                        .header("Authorization", authHeader(admin.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("name", "관리자가 수정함"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("관리자가 수정함"));
    }

    @Test
    void 비활성화하면_공개_목록과_상세에서_사라진다() throws Exception {
        SignedUpUser seller = signUpWithRole(UserRole.SELLER);
        Category category = createCategory();
        Product product = createProduct(seller.userId(), category.getId());

        mockMvc.perform(patch("/api/products/" + product.getId())
                        .header("Authorization", authHeader(seller.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("isActive", false))))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/products/" + product.getId())).andExpect(status().isNotFound());
    }

    @Test
    void 같은_상품에_같은_사용자가_두번_리뷰를_쓰면_409를_반환한다() throws Exception {
        SignedUpUser seller = signUpWithRole(UserRole.SELLER);
        SignedUpUser reviewer = signUpUser();
        Category category = createCategory();
        Product product = createProduct(seller.userId(), category.getId());

        mockMvc.perform(post("/api/products/" + product.getId() + "/reviews")
                        .header("Authorization", authHeader(reviewer.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("rating", 4, "content", "좋아요"))))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/products/" + product.getId() + "/reviews")
                        .header("Authorization", authHeader(reviewer.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("rating", 2, "content", "또 씀"))))
                .andExpect(status().isConflict());
    }

    @Test
    void 리뷰를_쓰면_상세의_평균평점에_반영된다() throws Exception {
        SignedUpUser seller = signUpWithRole(UserRole.SELLER);
        SignedUpUser reviewer = signUpUser();
        Category category = createCategory();
        Product product = createProduct(seller.userId(), category.getId());

        mockMvc.perform(post("/api/products/" + product.getId() + "/reviews")
                        .header("Authorization", authHeader(reviewer.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("rating", 4, "content", "좋아요"))))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/products/" + product.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reviewStats.average").value(4.0))
                .andExpect(jsonPath("$.reviewStats.count").value(1));
    }
}
