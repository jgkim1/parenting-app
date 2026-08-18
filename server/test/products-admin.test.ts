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

describe("상품 관리자 기능", () => {
  beforeEach(async () => {
    await resetDatabase();
  });

  describe("수정 권한", () => {
    it("본인이 등록한 상품은 SELLER가 수정할 수 있다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id, { name: "원래 이름" });

      const res = await api
        .patch(`/api/products/${product.id}`)
        .set(authHeader(seller.accessToken))
        .send({ name: "바뀐 이름", price: 20000 });

      expect(res.status).toBe(200);
      expect(res.body.name).toBe("바뀐 이름");
      expect(res.body.price).toBe(20000);
    });

    it("다른 SELLER의 상품은 수정할 수 없다", async () => {
      const owner = await signUpWithRole("SELLER");
      const stranger = await signUpWithRole("SELLER", { email: "stranger@example.com" });
      const category = await createCategory();
      const product = await createProduct(owner.userId, category.id);

      const res = await api
        .patch(`/api/products/${product.id}`)
        .set(authHeader(stranger.accessToken))
        .send({ name: "가로채기 시도" });

      expect(res.status).toBe(403);
    });

    it("ADMIN은 다른 사람이 등록한 상품도 수정할 수 있다", async () => {
      const seller = await signUpWithRole("SELLER");
      const admin = await signUpWithRole("ADMIN");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id);

      const res = await api
        .patch(`/api/products/${product.id}`)
        .set(authHeader(admin.accessToken))
        .send({ name: "관리자가 수정함" });

      expect(res.status).toBe(200);
      expect(res.body.name).toBe("관리자가 수정함");
    });

    it("CUSTOMER는 수정을 시도하면 403을 반환한다", async () => {
      const seller = await signUpWithRole("SELLER");
      const customer = await signUpUser();
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id);

      const res = await api
        .patch(`/api/products/${product.id}`)
        .set(authHeader(customer.accessToken))
        .send({ name: "고객이 시도" });

      expect(res.status).toBe(403);
    });
  });

  describe("비활성화(삭제)", () => {
    it("isActive:false로 바꾸면 공개 목록/상세에서 사라진다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id);

      const patchRes = await api
        .patch(`/api/products/${product.id}`)
        .set(authHeader(seller.accessToken))
        .send({ isActive: false });
      expect(patchRes.status).toBe(200);
      expect(patchRes.body.isActive).toBe(false);

      const listRes = await api.get("/api/products");
      expect(listRes.body.items).toHaveLength(0);

      const detailRes = await api.get(`/api/products/${product.id}`);
      expect(detailRes.status).toBe(404);
    });

    it("ADMIN이 includeInactive=true로 조회하면 비활성 상품도 보인다", async () => {
      const seller = await signUpWithRole("SELLER");
      const admin = await signUpWithRole("ADMIN");
      const category = await createCategory();
      await createProduct(seller.userId, category.id, { isActive: false });

      const res = await api
        .get("/api/products?includeInactive=true")
        .set(authHeader(admin.accessToken));

      expect(res.body.items).toHaveLength(1);
    });

    it("ADMIN이 아니면 includeInactive=true를 보내도 비활성 상품이 보이지 않는다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      await createProduct(seller.userId, category.id, { isActive: false });

      const res = await api
        .get("/api/products?includeInactive=true")
        .set(authHeader(seller.accessToken));

      expect(res.body.items).toHaveLength(0);
    });
  });
});
