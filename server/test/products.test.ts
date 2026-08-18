import { beforeEach, describe, expect, it } from "vitest";
import {
  api,
  authHeader,
  createCategory,
  createProduct,
  resetDatabase,
  signUpUser,
  signUpWithRole,
} from "./helpers";

describe("상품", () => {
  beforeEach(async () => {
    await resetDatabase();
  });

  describe("카테고리/목록/상세 조회", () => {
    it("카테고리 목록을 이름순으로 반환한다", async () => {
      await createCategory({ name: "나 카테고리", slug: "b-cat" });
      await createCategory({ name: "가 카테고리", slug: "a-cat" });

      const res = await api.get("/api/categories");
      expect(res.status).toBe(200);
      expect(res.body.map((c: { name: string }) => c.name)).toEqual(["가 카테고리", "나 카테고리"]);
    });

    it("페이지네이션과 카테고리 필터가 동작한다", async () => {
      const seller = await signUpWithRole("SELLER");
      const categoryA = await createCategory({ name: "A", slug: "cat-a" });
      const categoryB = await createCategory({ name: "B", slug: "cat-b" });
      await createProduct(seller.userId, categoryA.id, { name: "상품A1" });
      await createProduct(seller.userId, categoryA.id, { name: "상품A2" });
      await createProduct(seller.userId, categoryB.id, { name: "상품B1" });

      const filtered = await api.get(`/api/products?categoryId=${categoryA.id}`);
      expect(filtered.status).toBe(200);
      expect(filtered.body.total).toBe(2);
      expect(filtered.body.items).toHaveLength(2);

      const paged = await api.get("/api/products?page=1&pageSize=2");
      expect(paged.body.items).toHaveLength(2);
      expect(paged.body.totalPages).toBe(2);
    });

    it("비활성 상품은 목록에서 제외된다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      await createProduct(seller.userId, category.id, { isActive: false });

      const res = await api.get("/api/products");
      expect(res.body.items).toHaveLength(0);
    });

    it("존재하지 않는 상품 상세는 404를 반환한다", async () => {
      const res = await api.get("/api/products/00000000-0000-0000-0000-000000000000");
      expect(res.status).toBe(404);
    });

    it("상품 상세는 reviewStats(평균/개수)를 포함한다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id);

      const res = await api.get(`/api/products/${product.id}`);
      expect(res.status).toBe(200);
      expect(res.body.reviewStats).toEqual({ average: 0, count: 0 });
    });
  });

  describe("상품 등록 권한", () => {
    it("CUSTOMER 권한이면 403을 반환한다", async () => {
      const customer = await signUpUser();
      const category = await createCategory();

      const res = await api
        .post("/api/products")
        .set(authHeader(customer.accessToken))
        .send({
          categoryId: category.id,
          name: "새 상품",
          description: "설명",
          price: 5000,
          stock: 3,
        });

      expect(res.status).toBe(403);
    });

    it("SELLER 권한이면 상품을 등록할 수 있다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();

      const res = await api
        .post("/api/products")
        .set(authHeader(seller.accessToken))
        .send({
          categoryId: category.id,
          name: "새 상품",
          description: "설명",
          price: 5000,
          stock: 3,
        });

      expect(res.status).toBe(201);
      expect(res.body.name).toBe("새 상품");
    });

    it("토큰 없이 등록을 시도하면 401을 반환한다", async () => {
      const category = await createCategory();
      const res = await api.post("/api/products").send({
        categoryId: category.id,
        name: "새 상품",
        description: "설명",
        price: 5000,
        stock: 3,
      });
      expect(res.status).toBe(401);
    });
  });

  describe("리뷰", () => {
    it("리뷰를 작성하면 평균 평점과 개수에 반영된다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id);
      const reviewer = await signUpUser();

      const createRes = await api
        .post(`/api/products/${product.id}/reviews`)
        .set(authHeader(reviewer.accessToken))
        .send({ rating: 4, content: "좋아요" });
      expect(createRes.status).toBe(201);

      const detail = await api.get(`/api/products/${product.id}`);
      expect(detail.body.reviewStats).toEqual({ average: 4, count: 1 });
      expect(detail.body.reviews).toHaveLength(1);
    });

    it("같은 상품에 같은 사용자가 두 번 리뷰를 쓰면 409를 반환한다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id);
      const reviewer = await signUpUser();

      await api
        .post(`/api/products/${product.id}/reviews`)
        .set(authHeader(reviewer.accessToken))
        .send({ rating: 4, content: "좋아요" });

      const secondRes = await api
        .post(`/api/products/${product.id}/reviews`)
        .set(authHeader(reviewer.accessToken))
        .send({ rating: 2, content: "역시 좋아요" });

      expect(secondRes.status).toBe(409);
    });

    it("평점이 1~5 범위를 벗어나면 400을 반환한다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id);
      const reviewer = await signUpUser();

      const res = await api
        .post(`/api/products/${product.id}/reviews`)
        .set(authHeader(reviewer.accessToken))
        .send({ rating: 6, content: "만점 초과" });

      expect(res.status).toBe(400);
    });

    it("본인 리뷰만 수정/삭제할 수 있다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id);
      const author = await signUpUser();
      const stranger = await signUpUser();

      const createRes = await api
        .post(`/api/products/${product.id}/reviews`)
        .set(authHeader(author.accessToken))
        .send({ rating: 3, content: "보통이에요" });
      const reviewId = createRes.body.id;

      const strangerUpdate = await api
        .patch(`/api/reviews/${reviewId}`)
        .set(authHeader(stranger.accessToken))
        .send({ rating: 5, content: "가로채기 시도" });
      expect(strangerUpdate.status).toBe(403);

      const strangerDelete = await api
        .delete(`/api/reviews/${reviewId}`)
        .set(authHeader(stranger.accessToken));
      expect(strangerDelete.status).toBe(403);

      const ownerUpdate = await api
        .patch(`/api/reviews/${reviewId}`)
        .set(authHeader(author.accessToken))
        .send({ rating: 5, content: "다시 생각해보니 최고예요" });
      expect(ownerUpdate.status).toBe(200);
      expect(ownerUpdate.body.rating).toBe(5);

      const ownerDelete = await api
        .delete(`/api/reviews/${reviewId}`)
        .set(authHeader(author.accessToken));
      expect(ownerDelete.status).toBe(204);

      const detail = await api.get(`/api/products/${product.id}`);
      expect(detail.body.reviews).toHaveLength(0);
      expect(detail.body.reviewStats).toEqual({ average: 0, count: 0 });
    });
  });
});
