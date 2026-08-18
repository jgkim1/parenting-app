import { beforeEach, describe, expect, it } from "vitest";
import { api, authHeader, resetDatabase, signUpUser } from "./helpers";

describe("자녀 프로필", () => {
  beforeEach(async () => {
    await resetDatabase();
  });

  it("자녀를 등록하고 조회할 수 있다", async () => {
    const parent = await signUpUser();

    const createRes = await api
      .post("/api/children")
      .set(authHeader(parent.accessToken))
      .send({ nickname: "첫째", gender: "MALE", birthDate: "2024-01-15" });
    expect(createRes.status).toBe(201);
    expect(createRes.body.nickname).toBe("첫째");
    expect(createRes.body.gender).toBe("MALE");

    const listRes = await api.get("/api/children").set(authHeader(parent.accessToken));
    expect(listRes.status).toBe(200);
    expect(listRes.body).toHaveLength(1);
  });

  it("성별 없이도 등록할 수 있다", async () => {
    const parent = await signUpUser();
    const res = await api
      .post("/api/children")
      .set(authHeader(parent.accessToken))
      .send({ nickname: "둘째", birthDate: "2025-03-01" });

    expect(res.status).toBe(201);
    expect(res.body.gender).toBeNull();
  });

  it("본인의 자녀만 조회된다", async () => {
    const parentA = await signUpUser();
    const parentB = await signUpUser();

    await api
      .post("/api/children")
      .set(authHeader(parentA.accessToken))
      .send({ nickname: "A의 아이", birthDate: "2024-01-01" });
    await api
      .post("/api/children")
      .set(authHeader(parentB.accessToken))
      .send({ nickname: "B의 아이", birthDate: "2024-06-01" });

    const listA = await api.get("/api/children").set(authHeader(parentA.accessToken));
    expect(listA.body).toHaveLength(1);
    expect(listA.body[0].nickname).toBe("A의 아이");
  });

  it("본인 자녀만 수정/삭제할 수 있다", async () => {
    const parent = await signUpUser();
    const stranger = await signUpUser();

    const createRes = await api
      .post("/api/children")
      .set(authHeader(parent.accessToken))
      .send({ nickname: "첫째", birthDate: "2024-01-01" });
    const childId = createRes.body.id;

    const strangerUpdate = await api
      .patch(`/api/children/${childId}`)
      .set(authHeader(stranger.accessToken))
      .send({ nickname: "가로채기", birthDate: "2024-01-01" });
    expect(strangerUpdate.status).toBe(403);

    const strangerDelete = await api
      .delete(`/api/children/${childId}`)
      .set(authHeader(stranger.accessToken));
    expect(strangerDelete.status).toBe(403);

    const ownerUpdate = await api
      .patch(`/api/children/${childId}`)
      .set(authHeader(parent.accessToken))
      .send({ nickname: "첫째(수정됨)", gender: "FEMALE", birthDate: "2024-02-02" });
    expect(ownerUpdate.status).toBe(200);
    expect(ownerUpdate.body.nickname).toBe("첫째(수정됨)");
    expect(ownerUpdate.body.gender).toBe("FEMALE");

    const ownerDelete = await api
      .delete(`/api/children/${childId}`)
      .set(authHeader(parent.accessToken));
    expect(ownerDelete.status).toBe(204);

    const listAfter = await api.get("/api/children").set(authHeader(parent.accessToken));
    expect(listAfter.body).toHaveLength(0);
  });

  it("존재하지 않는 자녀를 수정/삭제하면 404를 반환한다", async () => {
    const parent = await signUpUser();
    const res = await api
      .patch("/api/children/00000000-0000-0000-0000-000000000000")
      .set(authHeader(parent.accessToken))
      .send({ nickname: "없음", birthDate: "2024-01-01" });
    expect(res.status).toBe(404);
  });

  it("토큰 없이 접근하면 401을 반환한다", async () => {
    const res = await api.get("/api/children");
    expect(res.status).toBe(401);
  });
});
