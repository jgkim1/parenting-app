import { beforeEach, describe, expect, it } from "vitest";
import { api, authHeader, resetDatabase, signUpUser } from "./helpers";

describe("커뮤니티", () => {
  beforeEach(async () => {
    await resetDatabase();
  });

  describe("게시글", () => {
    it("작성한 게시글이 목록과 검색 결과에 나온다", async () => {
      const author = await signUpUser();
      await api
        .post("/api/posts")
        .set(authHeader(author.accessToken))
        .send({ title: "밤중 수유 언제까지 하셨나요", content: "9개월인데 아직도요" });
      await api
        .post("/api/posts")
        .set(authHeader(author.accessToken))
        .send({ title: "이유식 거부기 극복 후기", content: "드디어 잘 먹어요" });

      const all = await api.get("/api/posts");
      expect(all.body.total).toBe(2);

      const searched = await api.get("/api/posts?q=수유");
      expect(searched.body.items).toHaveLength(1);
      expect(searched.body.items[0].title).toBe("밤중 수유 언제까지 하셨나요");
    });

    it("조회할 때마다 조회수가 오르고, 로그인 여부에 따라 좋아요 상태가 다르게 보인다", async () => {
      const author = await signUpUser();
      const createRes = await api
        .post("/api/posts")
        .set(authHeader(author.accessToken))
        .send({ title: "제목", content: "내용" });
      const postId = createRes.body.id;

      const anonymous = await api.get(`/api/posts/${postId}`);
      expect(anonymous.body.viewCount).toBe(1);
      expect(anonymous.body.likedByMe).toBe(false);

      await api.post(`/api/posts/${postId}/like`).set(authHeader(author.accessToken));

      const loggedIn = await api.get(`/api/posts/${postId}`).set(authHeader(author.accessToken));
      expect(loggedIn.body.viewCount).toBe(2);
      expect(loggedIn.body.likedByMe).toBe(true);
    });

    it("본인 게시글만 수정/삭제할 수 있다", async () => {
      const author = await signUpUser();
      const stranger = await signUpUser();
      const createRes = await api
        .post("/api/posts")
        .set(authHeader(author.accessToken))
        .send({ title: "원래 제목", content: "원래 내용" });
      const postId = createRes.body.id;

      const strangerUpdate = await api
        .patch(`/api/posts/${postId}`)
        .set(authHeader(stranger.accessToken))
        .send({ title: "가로채기", content: "가로채기" });
      expect(strangerUpdate.status).toBe(403);

      const strangerDelete = await api
        .delete(`/api/posts/${postId}`)
        .set(authHeader(stranger.accessToken));
      expect(strangerDelete.status).toBe(403);

      const ownerUpdate = await api
        .patch(`/api/posts/${postId}`)
        .set(authHeader(author.accessToken))
        .send({ title: "수정된 제목", content: "수정된 내용" });
      expect(ownerUpdate.status).toBe(200);
      expect(ownerUpdate.body.title).toBe("수정된 제목");

      const ownerDelete = await api
        .delete(`/api/posts/${postId}`)
        .set(authHeader(author.accessToken));
      expect(ownerDelete.status).toBe(204);

      const afterDelete = await api.get(`/api/posts/${postId}`);
      expect(afterDelete.status).toBe(404);
    });
  });

  describe("댓글", () => {
    it("댓글을 작성할 수 있고, 본인 댓글만 삭제할 수 있다", async () => {
      const author = await signUpUser();
      const commenter = await signUpUser();
      const stranger = await signUpUser();

      const postRes = await api
        .post("/api/posts")
        .set(authHeader(author.accessToken))
        .send({ title: "제목", content: "내용" });
      const postId = postRes.body.id;

      const commentRes = await api
        .post(`/api/posts/${postId}/comments`)
        .set(authHeader(commenter.accessToken))
        .send({ content: "저도 궁금해요" });
      expect(commentRes.status).toBe(201);

      const detail = await api.get(`/api/posts/${postId}`);
      expect(detail.body.comments).toHaveLength(1);

      const strangerDelete = await api
        .delete(`/api/comments/${commentRes.body.id}`)
        .set(authHeader(stranger.accessToken));
      expect(strangerDelete.status).toBe(403);

      const ownerDelete = await api
        .delete(`/api/comments/${commentRes.body.id}`)
        .set(authHeader(commenter.accessToken));
      expect(ownerDelete.status).toBe(204);

      const afterDelete = await api.get(`/api/posts/${postId}`);
      expect(afterDelete.body.comments).toHaveLength(0);
    });
  });

  describe("좋아요 토글", () => {
    it("두 번 누르면 좋아요가 취소된다", async () => {
      const author = await signUpUser();
      const liker = await signUpUser();
      const postRes = await api
        .post("/api/posts")
        .set(authHeader(author.accessToken))
        .send({ title: "제목", content: "내용" });
      const postId = postRes.body.id;

      const firstLike = await api.post(`/api/posts/${postId}/like`).set(authHeader(liker.accessToken));
      expect(firstLike.body).toEqual({ liked: true, likeCount: 1 });

      const secondLike = await api.post(`/api/posts/${postId}/like`).set(authHeader(liker.accessToken));
      expect(secondLike.body).toEqual({ liked: false, likeCount: 0 });
    });

    it("동시에 여러 번 좋아요 요청을 보내도 서버가 에러 없이 처리한다", async () => {
      const author = await signUpUser();
      const liker = await signUpUser();
      const postRes = await api
        .post("/api/posts")
        .set(authHeader(author.accessToken))
        .send({ title: "제목", content: "내용" });
      const postId = postRes.body.id;

      const results = await Promise.all(
        Array.from({ length: 5 }, () =>
          api.post(`/api/posts/${postId}/like`).set(authHeader(liker.accessToken)),
        ),
      );

      for (const res of results) {
        expect(res.status).toBe(200);
      }

      const detail = await api.get(`/api/posts/${postId}`).set(authHeader(liker.accessToken));
      expect(detail.body.likeCount).toBe(detail.body.likedByMe ? 1 : 0);
    });
  });
});
