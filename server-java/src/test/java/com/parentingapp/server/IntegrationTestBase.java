package com.parentingapp.server;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.parentingapp.server.domain.ArticleCategory;
import com.parentingapp.server.domain.Category;
import com.parentingapp.server.domain.Product;
import com.parentingapp.server.domain.User;
import com.parentingapp.server.domain.UserRole;
import com.parentingapp.server.repository.ArticleCategoryRepository;
import com.parentingapp.server.repository.CategoryRepository;
import com.parentingapp.server.repository.ProductRepository;
import com.parentingapp.server.repository.UserRepository;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

// 각 테스트 메서드를 트랜잭션으로 감싸고 끝나면 롤백해, 실제 MySQL 테스트 DB(parenting_app_test)를
// 써도 테스트끼리 데이터가 섞이지 않게 한다. Node 버전의 resetDatabase()와 동일한 목적.
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@ExtendWith(SpringExtension.class)
@Transactional
public abstract class IntegrationTestBase {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    @Autowired
    protected UserRepository userRepository;

    @Autowired
    protected CategoryRepository categoryRepository;

    @Autowired
    protected ArticleCategoryRepository articleCategoryRepository;

    @Autowired
    protected ProductRepository productRepository;

    @Autowired
    protected PasswordEncoder passwordEncoder;

    private static final AtomicInteger COUNTER = new AtomicInteger();

    protected record SignedUpUser(String userId, String email, String password, String accessToken, String refreshToken) {}

    protected SignedUpUser signUpUser() throws Exception {
        int n = COUNTER.incrementAndGet();
        String email = "user" + n + "@example.com";
        String password = "password123";
        String body = mockMvc
                .perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(java.util.Map.of(
                                "email", email, "password", password, "nickname", "테스터" + n))))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        JsonNode json = objectMapper.readTree(body);
        return new SignedUpUser(
                json.get("user").get("id").asText(),
                email,
                password,
                json.get("accessToken").asText(),
                json.get("refreshToken").asText());
    }

    protected SignedUpUser signUpWithRole(UserRole role) throws Exception {
        SignedUpUser user = signUpUser();
        User entity = userRepository.findById(user.userId()).orElseThrow();
        entity.setRole(role);
        userRepository.saveAndFlush(entity);

        // JWT에는 발급 시점의 role이 그대로 박혀있으므로, role을 올린 뒤에는 재로그인해서
        // 새 토큰을 받아야 권한 검증을 통과할 수 있다.
        String body = mockMvc
                .perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                java.util.Map.of("email", user.email(), "password", user.password()))))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        JsonNode json = objectMapper.readTree(body);
        return new SignedUpUser(
                user.userId(), user.email(), user.password(), json.get("accessToken").asText(), json.get("refreshToken").asText());
    }

    protected String authHeader(String accessToken) {
        return "Bearer " + accessToken;
    }

    protected Category createCategory() {
        int n = COUNTER.incrementAndGet();
        Category category = new Category();
        category.setName("테스트카테고리" + n);
        category.setSlug("test-category-" + n);
        return categoryRepository.saveAndFlush(category);
    }

    protected ArticleCategory createArticleCategory() {
        int n = COUNTER.incrementAndGet();
        ArticleCategory category = new ArticleCategory();
        category.setName("테스트정보카테고리" + n);
        category.setSlug("test-article-category-" + n);
        return articleCategoryRepository.saveAndFlush(category);
    }

    protected Product createProduct(String sellerId, String categoryId) {
        int n = COUNTER.incrementAndGet();
        Product product = new Product();
        product.setSeller(userRepository.findById(sellerId).orElseThrow());
        product.setCategory(categoryRepository.findById(categoryId).orElseThrow());
        product.setName("테스트상품" + n);
        product.setDescription("테스트 상품 설명입니다.");
        product.setPrice(10000);
        product.setStock(10);
        return productRepository.saveAndFlush(product);
    }
}
