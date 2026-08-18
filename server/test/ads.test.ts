import { beforeEach, describe, expect, it } from "vitest";
import { api, authHeader, resetDatabase, signUpUser, signUpWithRole } from "./helpers";

describe("광고(Ad)", () => {
  beforeEach(async () => {
    await resetDatabase();
  });

  describe("등록/수정/삭제 권한", () => {
    it("ADMIN이 아니면 등록 시 403을 반환한다", async () => {
      const customer = await signUpUser();

      const res = await api
        .post("/api/ads")
        .set(authHeader(customer.accessToken))
        .send({
          placement: "TODAY",
          title: "육아용품 특가",
          imageUrl: "https://example.com/ad.png",
        });

      expect(res.status).toBe(403);
    });

    it("ADMIN은 광고를 등록/수정/삭제할 수 있다", async () => {
      const admin = await signUpWithRole("ADMIN");

      const createRes = await api
        .post("/api/ads")
        .set(authHeader(admin.accessToken))
        .send({
          placement: "TODAY",
          title: "육아용품 특가",
          imageUrl: "https://example.com/ad.png",
          linkUrl: "https://example.com",
          sortOrder: 1,
        });
      expect(createRes.status).toBe(201);
      expect(createRes.body.isActive).toBe(true);
      const adId = createRes.body.id;

      const updateRes = await api
        .patch(`/api/ads/${adId}`)
        .set(authHeader(admin.accessToken))
        .send({ title: "수정된 제목" });
      expect(updateRes.status).toBe(200);
      expect(updateRes.body.title).toBe("수정된 제목");

      const deleteRes = await api.delete(`/api/ads/${adId}`).set(authHeader(admin.accessToken));
      expect(deleteRes.status).toBe(204);
    });

    it("올바르지 않은 placement로 등록하면 400을 반환한다", async () => {
      const admin = await signUpWithRole("ADMIN");

      const res = await api
        .post("/api/ads")
        .set(authHeader(admin.accessToken))
        .send({ placement: "NOT_A_PLACEMENT", title: "제목", imageUrl: "https://example.com/ad.png" });

      expect(res.status).toBe(400);
    });
  });

  describe("공개 조회", () => {
    it("placement로 필터링해 활성 광고만 정렬 순서대로 반환한다", async () => {
      const admin = await signUpWithRole("ADMIN");
      await api
        .post("/api/ads")
        .set(authHeader(admin.accessToken))
        .send({ placement: "TODAY", title: "두 번째", imageUrl: "https://example.com/2.png", sortOrder: 2 });
      await api
        .post("/api/ads")
        .set(authHeader(admin.accessToken))
        .send({ placement: "TODAY", title: "첫 번째", imageUrl: "https://example.com/1.png", sortOrder: 1 });
      await api
        .post("/api/ads")
        .set(authHeader(admin.accessToken))
        .send({ placement: "PRODUCT_LIST", title: "다른 위치", imageUrl: "https://example.com/3.png" });

      const res = await api.get("/api/ads?placement=TODAY");

      expect(res.status).toBe(200);
      expect(res.body.map((ad: { title: string }) => ad.title)).toEqual(["첫 번째", "두 번째"]);
    });

    it("비활성 광고는 일반 사용자에게 보이지 않는다", async () => {
      const admin = await signUpWithRole("ADMIN");
      const created = await api
        .post("/api/ads")
        .set(authHeader(admin.accessToken))
        .send({ placement: "TODAY", title: "제목", imageUrl: "https://example.com/1.png" });
      await api
        .patch(`/api/ads/${created.body.id}`)
        .set(authHeader(admin.accessToken))
        .send({ isActive: false });

      const publicRes = await api.get("/api/ads?placement=TODAY");
      expect(publicRes.body).toHaveLength(0);

      const adminRes = await api
        .get("/api/ads?placement=TODAY&includeInactive=true")
        .set(authHeader(admin.accessToken));
      expect(adminRes.body).toHaveLength(1);
    });
  });
});
