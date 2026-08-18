import { beforeEach, describe, expect, it } from "vitest";
import { api, resetDatabase, signUpUser } from "./helpers";

describe("테스트 인프라 smoke test", () => {
  beforeEach(async () => {
    await resetDatabase();
  });

  it("헬스체크가 응답한다", async () => {
    const res = await api.get("/health");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: "ok" });
  });

  it("회원가입 헬퍼로 사용자를 만들고 초기화 후에는 남아있지 않는다", async () => {
    const user = await signUpUser();
    expect(user.accessToken).toBeTruthy();

    const me = await api.get("/api/users/me").set("Authorization", `Bearer ${user.accessToken}`);
    expect(me.status).toBe(200);
    expect(me.body.email).toBe(user.email);
  });

  it("resetDatabase 이후에는 이전 테스트의 사용자가 사라진다", async () => {
    const res = await api.get("/api/products");
    expect(res.status).toBe(200);
    expect(res.body.items).toEqual([]);
  });
});
