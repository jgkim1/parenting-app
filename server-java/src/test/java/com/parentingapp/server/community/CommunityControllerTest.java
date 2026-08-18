package com.parentingapp.server.community;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.parentingapp.server.IntegrationTestBase;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

class CommunityControllerTest extends IntegrationTestBase {

    private String createPost(String accessToken) throws Exception {
        String body = mockMvc.perform(post("/api/posts")
                        .header("Authorization", authHeader(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("title", "제목", "content", "내용"))))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        return objectMapper.readTree(body).get("id").asText();
    }

    @Test
    void 좋아요를_두번_누르면_취소된다() throws Exception {
        SignedUpUser author = signUpUser();
        SignedUpUser liker = signUpUser();
        String postId = createPost(author.accessToken());

        mockMvc.perform(post("/api/posts/" + postId + "/like").header("Authorization", authHeader(liker.accessToken())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.liked").value(true))
                .andExpect(jsonPath("$.likeCount").value(1));

        mockMvc.perform(post("/api/posts/" + postId + "/like").header("Authorization", authHeader(liker.accessToken())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.liked").value(false))
                .andExpect(jsonPath("$.likeCount").value(0));
    }

    @Test
    void 본인_게시글이_아니면_삭제할_수_없다() throws Exception {
        SignedUpUser author = signUpUser();
        SignedUpUser stranger = signUpUser();
        String postId = createPost(author.accessToken());

        mockMvc.perform(delete("/api/posts/" + postId).header("Authorization", authHeader(stranger.accessToken())))
                .andExpect(status().isForbidden());

        mockMvc.perform(delete("/api/posts/" + postId).header("Authorization", authHeader(author.accessToken())))
                .andExpect(status().isNoContent());
    }

    @Test
    void 댓글을_달면_목록에_보이고_본인_댓글만_삭제할_수_있다() throws Exception {
        SignedUpUser author = signUpUser();
        SignedUpUser commenter = signUpUser();
        SignedUpUser stranger = signUpUser();
        String postId = createPost(author.accessToken());

        String commentBody = mockMvc.perform(post("/api/posts/" + postId + "/comments")
                        .header("Authorization", authHeader(commenter.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("content", "댓글입니다"))))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();
        String commentId = objectMapper.readTree(commentBody).get("id").asText();

        mockMvc.perform(delete("/api/comments/" + commentId).header("Authorization", authHeader(stranger.accessToken())))
                .andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/comments/" + commentId).header("Authorization", authHeader(commenter.accessToken())))
                .andExpect(status().isNoContent());
    }
}
