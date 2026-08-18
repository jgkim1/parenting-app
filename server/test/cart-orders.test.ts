import { beforeEach, describe, expect, it } from "vitest";
import { prisma } from "../src/config/prisma";
import {
  api,
  authHeader,
  createCategory,
  createProduct,
  resetDatabase,
  signUpUser,
  signUpWithRole,
} from "./helpers";

describe("장바구니/주문", () => {
  beforeEach(async () => {
    await resetDatabase();
  });

  describe("장바구니", () => {
    it("상품을 담고 다시 담으면 수량이 합산된다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id, { stock: 10 });
      const buyer = await signUpUser();

      await api
        .post("/api/cart/items")
        .set(authHeader(buyer.accessToken))
        .send({ productId: product.id, quantity: 2 });
      const res = await api
        .post("/api/cart/items")
        .set(authHeader(buyer.accessToken))
        .send({ productId: product.id, quantity: 3 });

      expect(res.status).toBe(200);
      expect(res.body.items).toHaveLength(1);
      expect(res.body.items[0].quantity).toBe(5);
    });

    it("재고보다 많은 수량을 담으려 하면 400을 반환한다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id, { stock: 3 });
      const buyer = await signUpUser();

      const res = await api
        .post("/api/cart/items")
        .set(authHeader(buyer.accessToken))
        .send({ productId: product.id, quantity: 4 });

      expect(res.status).toBe(400);
    });

    it("수량을 변경할 수 있고, 재고 초과 변경은 거부된다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id, { stock: 5 });
      const buyer = await signUpUser();

      await api
        .post("/api/cart/items")
        .set(authHeader(buyer.accessToken))
        .send({ productId: product.id, quantity: 1 });

      const updated = await api
        .patch(`/api/cart/items/${product.id}`)
        .set(authHeader(buyer.accessToken))
        .send({ quantity: 5 });
      expect(updated.status).toBe(200);
      expect(updated.body.items[0].quantity).toBe(5);

      const overLimit = await api
        .patch(`/api/cart/items/${product.id}`)
        .set(authHeader(buyer.accessToken))
        .send({ quantity: 6 });
      expect(overLimit.status).toBe(400);
    });

    it("장바구니에서 상품을 삭제할 수 있다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id);
      const buyer = await signUpUser();

      await api
        .post("/api/cart/items")
        .set(authHeader(buyer.accessToken))
        .send({ productId: product.id, quantity: 1 });

      const res = await api
        .delete(`/api/cart/items/${product.id}`)
        .set(authHeader(buyer.accessToken));

      expect(res.status).toBe(200);
      expect(res.body.items).toHaveLength(0);
    });
  });

  describe("주문", () => {
    it("장바구니가 비어 있으면 주문 생성이 거부된다", async () => {
      const buyer = await signUpUser();
      const res = await api
        .post("/api/orders")
        .set(authHeader(buyer.accessToken))
        .send({ shippingAddr: "서울시 강남구" });

      expect(res.status).toBe(400);
    });

    it("주문 생성 시 재고가 차감되고 장바구니가 비워지며 가격이 스냅샷된다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id, { price: 10000, stock: 5 });
      const buyer = await signUpUser();

      await api
        .post("/api/cart/items")
        .set(authHeader(buyer.accessToken))
        .send({ productId: product.id, quantity: 2 });

      const orderRes = await api
        .post("/api/orders")
        .set(authHeader(buyer.accessToken))
        .send({ shippingAddr: "서울시 강남구 테헤란로 1" });

      expect(orderRes.status).toBe(201);
      expect(orderRes.body.status).toBe("PENDING_PAYMENT");
      expect(orderRes.body.totalAmount).toBe(20000);
      expect(orderRes.body.items[0].priceAtOrder).toBe(10000);

      const productAfter = await prisma.product.findUniqueOrThrow({ where: { id: product.id } });
      expect(productAfter.stock).toBe(3);

      const cartRes = await api.get("/api/cart").set(authHeader(buyer.accessToken));
      expect(cartRes.body.items).toHaveLength(0);
    });

    it("주문 시점에 재고가 부족하면 거부되고 아무것도 차감되지 않는다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id, { stock: 2 });
      const buyer = await signUpUser();

      await api
        .post("/api/cart/items")
        .set(authHeader(buyer.accessToken))
        .send({ productId: product.id, quantity: 2 });

      // 다른 경로로 재고가 먼저 소진된 상황을 시뮬레이션한다.
      await prisma.product.update({ where: { id: product.id }, data: { stock: 1 } });

      const orderRes = await api
        .post("/api/orders")
        .set(authHeader(buyer.accessToken))
        .send({ shippingAddr: "서울시 강남구" });

      expect(orderRes.status).toBe(400);

      const productAfter = await prisma.product.findUniqueOrThrow({ where: { id: product.id } });
      expect(productAfter.stock).toBe(1);

      const cartRes = await api.get("/api/cart").set(authHeader(buyer.accessToken));
      expect(cartRes.body.items).toHaveLength(1);
    });

    it("본인 주문 목록만 조회되고, 다른 사용자 주문 상세는 404를 반환한다", async () => {
      const seller = await signUpWithRole("SELLER");
      const category = await createCategory();
      const product = await createProduct(seller.userId, category.id, { stock: 10 });

      const buyerA = await signUpUser();
      await api
        .post("/api/cart/items")
        .set(authHeader(buyerA.accessToken))
        .send({ productId: product.id, quantity: 1 });
      const orderA = await api
        .post("/api/orders")
        .set(authHeader(buyerA.accessToken))
        .send({ shippingAddr: "A의 주소" });

      const buyerB = await signUpUser();
      await api
        .post("/api/cart/items")
        .set(authHeader(buyerB.accessToken))
        .send({ productId: product.id, quantity: 1 });
      await api
        .post("/api/orders")
        .set(authHeader(buyerB.accessToken))
        .send({ shippingAddr: "B의 주소" });

      const listA = await api.get("/api/orders").set(authHeader(buyerA.accessToken));
      expect(listA.body.items).toHaveLength(1);
      expect(listA.body.items[0].shippingAddr).toBe("A의 주소");

      const crossAccess = await api
        .get(`/api/orders/${orderA.body.id}`)
        .set(authHeader(buyerB.accessToken));
      expect(crossAccess.status).toBe(404);
    });
  });
});
