import { beforeEach, describe, expect, it } from "vitest";
import {
  api,
  authHeader,
  createArticleCategory,
  resetDatabase,
  signUpUser,
  signUpWithRole,
} from "./helpers";

describe("육아정보(아티클)", () => {
  beforeEach(async () => {
    await resetDatabase();
  });

  describe("등록 권한", () => {
    it("ADMIN이 아니면 등록 시 403을 반환한다", async () => {
      const customer = await signUpUser();
      const category = await createArticleCategory();

      const res = await api
        .post("/api/articles")
        .set(authHeader(customer.accessToken))
        .send({ categoryId: category.id, title: "제목", content: "본문" });

      expect(res.status).toBe(403);
    });

    it("ADMIN은 아티클을 등록할 수 있다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const category = await createArticleCategory();

      const res = await api
        .post("/api/articles")
        .set(authHeader(admin.accessToken))
        .send({ categoryId: category.id, title: "이유식 시작하기", content: "본문 내용" });

      expect(res.status).toBe(201);
      expect(res.body.title).toBe("이유식 시작하기");
      expect(res.body.isActive).toBe(true);
    });
  });

  describe("목록/상세 조회", () => {
    it("비공개(isActive:false) 아티클은 목록/상세에서 제외된다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const category = await createArticleCategory();
      const created = await api
        .post("/api/articles")
        .set(authHeader(admin.accessToken))
        .send({ categoryId: category.id, title: "비공개 글", content: "본문" });

      await api
        .patch(`/api/articles/${created.body.id}`)
        .set(authHeader(admin.accessToken))
        .send({ isActive: false });

      const listRes = await api.get("/api/articles");
      expect(listRes.body.items).toHaveLength(0);

      const detailRes = await api.get(`/api/articles/${created.body.id}`);
      expect(detailRes.status).toBe(404);
    });

    it("ADMIN이 includeInactive=true로 조회하면 비공개 아티클도 보인다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const category = await createArticleCategory();
      const created = await api
        .post("/api/articles")
        .set(authHeader(admin.accessToken))
        .send({ categoryId: category.id, title: "비공개 글", content: "본문" });
      await api
        .patch(`/api/articles/${created.body.id}`)
        .set(authHeader(admin.accessToken))
        .send({ isActive: false });

      const listRes = await api
        .get("/api/articles?includeInactive=true")
        .set(authHeader(admin.accessToken));
      expect(listRes.body.items).toHaveLength(1);

      const detailRes = await api
        .get(`/api/articles/${created.body.id}`)
        .set(authHeader(admin.accessToken));
      expect(detailRes.status).toBe(200);
    });

    it("조회할 때마다 조회수가 1씩 증가한다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const category = await createArticleCategory();
      const created = await api
        .post("/api/articles")
        .set(authHeader(admin.accessToken))
        .send({ categoryId: category.id, title: "제목", content: "본문" });

      await api.get(`/api/articles/${created.body.id}`);
      const second = await api.get(`/api/articles/${created.body.id}`);

      expect(second.body.viewCount).toBe(2);
    });

    it("관리자가 includeInactive로 미리보기하면 조회수가 오르지 않는다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const category = await createArticleCategory();
      const created = await api
        .post("/api/articles")
        .set(authHeader(admin.accessToken))
        .send({ categoryId: category.id, title: "제목", content: "본문" });

      const res = await api
        .get(`/api/articles/${created.body.id}?includeInactive=true`)
        .set(authHeader(admin.accessToken));

      expect(res.body.viewCount).toBe(0);
    });
  });

  describe("수정/삭제 권한", () => {
    it("ADMIN이 아니면 수정 시 403을 반환한다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const customer = await signUpUser();
      const category = await createArticleCategory();
      const created = await api
        .post("/api/articles")
        .set(authHeader(admin.accessToken))
        .send({ categoryId: category.id, title: "제목", content: "본문" });

      const res = await api
        .patch(`/api/articles/${created.body.id}`)
        .set(authHeader(customer.accessToken))
        .send({ title: "가로채기 시도" });

      expect(res.status).toBe(403);
    });

    it("ADMIN은 아티클을 수정할 수 있다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const category = await createArticleCategory();
      const created = await api
        .post("/api/articles")
        .set(authHeader(admin.accessToken))
        .send({ categoryId: category.id, title: "원래 제목", content: "본문" });

      const res = await api
        .patch(`/api/articles/${created.body.id}`)
        .set(authHeader(admin.accessToken))
        .send({ title: "바뀐 제목" });

      expect(res.status).toBe(200);
      expect(res.body.title).toBe("바뀐 제목");
    });

    it("ADMIN이 아니면 삭제 시 403을 반환한다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const customer = await signUpUser();
      const category = await createArticleCategory();
      const created = await api
        .post("/api/articles")
        .set(authHeader(admin.accessToken))
        .send({ categoryId: category.id, title: "제목", content: "본문" });

      const res = await api
        .delete(`/api/articles/${created.body.id}`)
        .set(authHeader(customer.accessToken));

      expect(res.status).toBe(403);
    });

    it("ADMIN은 아티클을 삭제할 수 있고, 삭제 후에는 404를 반환한다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const category = await createArticleCategory();
      const created = await api
        .post("/api/articles")
        .set(authHeader(admin.accessToken))
        .send({ categoryId: category.id, title: "제목", content: "본문" });

      const deleteRes = await api
        .delete(`/api/articles/${created.body.id}`)
        .set(authHeader(admin.accessToken));
      expect(deleteRes.status).toBe(204);

      const getRes = await api
        .get(`/api/articles/${created.body.id}`)
        .set(authHeader(admin.accessToken));
      expect(getRes.status).toBe(404);
    });
  });
});
