package com.parentingapp.server.auth;

import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.parentingapp.server.IntegrationTestBase;
import java.util.Map;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

class AuthControllerTest extends IntegrationTestBase {

    @Nested
    class Signup {
        @Test
        void 이메일이_중복되면_409를_반환한다() throws Exception {
            SignedUpUser first = signUpUser();
            mockMvc.perform(post("/api/auth/signup")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of(
                                    "email", first.email(), "password", "password123", "nickname", "다른닉네임"))))
                    .andExpect(status().isConflict());
        }

        @Test
        void 비밀번호가_8자_미만이면_400을_반환한다() throws Exception {
            mockMvc.perform(post("/api/auth/signup")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(
                                    Map.of("email", "short@example.com", "password", "1234567", "nickname", "테스터"))))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    class Login {
        @Test
        void 올바른_정보면_토큰을_발급한다() throws Exception {
            SignedUpUser user = signUpUser();
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(
                                    Map.of("email", user.email(), "password", user.password()))))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.accessToken", notNullValue()))
                    .andExpect(jsonPath("$.refreshToken", notNullValue()));
        }

        @Test
        void 비밀번호가_틀리면_401을_반환한다() throws Exception {
            SignedUpUser user = signUpUser();
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("email", user.email(), "password", "wrong-pass"))))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    class Refresh {
        @Test
        void 리프레시_토큰을_한번_쓰면_재사용할_수_없다() throws Exception {
            SignedUpUser user = signUpUser();

            String firstRefreshBody = mockMvc.perform(post("/api/auth/refresh")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("refreshToken", user.refreshToken()))))
                    .andExpect(status().isOk())
                    .andReturn()
                    .getResponse()
                    .getContentAsString();
            String newRefreshToken = objectMapper.readTree(firstRefreshBody).get("refreshToken").asText();

            // 이미 사용(회전)된 옛 리프레시 토큰은 재사용할 수 없어야 한다(재사용 공격 방지).
            mockMvc.perform(post("/api/auth/refresh")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("refreshToken", user.refreshToken()))))
                    .andExpect(status().isUnauthorized());

            // 새로 발급받은 토큰은 정상 동작해야 한다.
            mockMvc.perform(post("/api/auth/refresh")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("refreshToken", newRefreshToken))))
                    .andExpect(status().isOk());
        }

        @Test
        void 서로_다른_시점에_발급해도_토큰_문자열이_겹치지_않는다() throws Exception {
            SignedUpUser user = signUpUser();
            String body1 = mockMvc.perform(post("/api/auth/refresh")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("refreshToken", user.refreshToken()))))
                    .andExpect(status().isOk())
                    .andReturn()
                    .getResponse()
                    .getContentAsString();

            SignedUpUser user2 = signUpUser();
            String body2 = mockMvc.perform(post("/api/auth/refresh")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("refreshToken", user2.refreshToken()))))
                    .andExpect(status().isOk())
                    .andReturn()
                    .getResponse()
                    .getContentAsString();

            String token1 = objectMapper.readTree(body1).get("refreshToken").asText();
            String token2 = objectMapper.readTree(body2).get("refreshToken").asText();
            org.junit.jupiter.api.Assertions.assertNotEquals(token1, token2);
        }
    }

    @Nested
    class Logout {
        @Test
        void 로그아웃하면_리프레시_토큰이_무효화된다() throws Exception {
            SignedUpUser user = signUpUser();

            mockMvc.perform(post("/api/auth/logout")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("refreshToken", user.refreshToken()))))
                    .andExpect(status().isNoContent());

            mockMvc.perform(post("/api/auth/refresh")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("refreshToken", user.refreshToken()))))
                    .andExpect(status().isUnauthorized());
        }
    }
}
