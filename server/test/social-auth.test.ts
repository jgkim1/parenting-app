import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { api, resetDatabase } from "./helpers";
import { env } from "../src/config/env";
import { prisma } from "../src/config/prisma";

const { verifyIdTokenMock } = vi.hoisted(() => ({ verifyIdTokenMock: vi.fn() }));

vi.mock("google-auth-library", () => ({
  // new로 호출되므로 화살표 함수가 아닌 일반 함수로 mock 구현을 만들어야 한다.
  OAuth2Client: vi.fn().mockImplementation(function () {
    return { verifyIdToken: verifyIdTokenMock };
  }),
}));

function mockKakaoProfile(response: { ok: boolean; body?: unknown }) {
  vi.stubGlobal(
    "fetch",
    vi.fn().mockResolvedValue({
      ok: response.ok,
      json: async () => response.body,
    }),
  );
}

function mockGooglePayload(payload: Record<string, unknown> | null) {
  verifyIdTokenMock.mockResolvedValue({ getPayload: () => payload });
}

describe("소셜 로그인", () => {
  beforeEach(async () => {
    await resetDatabase();
    verifyIdTokenMock.mockReset();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  describe("카카오", () => {
    it("처음 로그인하면 계정을 새로 만들고 토큰을 발급한다", async () => {
      mockKakaoProfile({
        ok: true,
        body: {
          id: 111,
          kakao_account: { email: "kakao111@example.com", profile: { nickname: "카카오유저" } },
        },
      });

      const res = await api.post("/api/auth/kakao").send({ accessToken: "valid-kakao-token" });

      expect(res.status).toBe(200);
      expect(res.body.user.email).toBe("kakao111@example.com");
      expect(res.body.user.nickname).toBe("카카오유저");
      expect(res.body.accessToken).toBeTruthy();

      const user = await prisma.user.findUnique({ where: { email: "kakao111@example.com" } });
      expect(user?.provider).toBe("KAKAO");
      expect(user?.providerId).toBe("111");
      expect(user?.passwordHash).toBeNull();
    });

    it("이메일 제공에 동의하지 않은 사용자도 더미 이메일로 가입된다", async () => {
      mockKakaoProfile({ ok: true, body: { id: 222 } });

      const res = await api.post("/api/auth/kakao").send({ accessToken: "valid-kakao-token" });

      expect(res.status).toBe(200);
      expect(res.body.user.email).toContain("222");
      expect(res.body.user.nickname).toContain("222");
    });

    it("같은 카카오 계정으로 다시 로그인하면 새 계정을 만들지 않는다", async () => {
      mockKakaoProfile({
        ok: true,
        body: { id: 333, kakao_account: { email: "k333@example.com", profile: { nickname: "K" } } },
      });

      const first = await api.post("/api/auth/kakao").send({ accessToken: "t1" });
      const second = await api.post("/api/auth/kakao").send({ accessToken: "t2" });

      expect(first.body.user.id).toBe(second.body.user.id);
      const count = await prisma.user.count();
      expect(count).toBe(1);
    });

    it("카카오 API가 실패 응답을 주면 401을 반환한다", async () => {
      mockKakaoProfile({ ok: false });

      const res = await api.post("/api/auth/kakao").send({ accessToken: "invalid-token" });
      expect(res.status).toBe(401);
    });

    it("이미 이메일/비밀번호로 가입된 이메일이면 409를 반환한다", async () => {
      await api
        .post("/api/auth/signup")
        .send({ email: "shared@example.com", password: "password123", nickname: "로컬유저" });

      mockKakaoProfile({
        ok: true,
        body: { id: 444, kakao_account: { email: "shared@example.com", profile: { nickname: "K" } } },
      });

      const res = await api.post("/api/auth/kakao").send({ accessToken: "t" });
      expect(res.status).toBe(409);
    });

    it("액세스 토큰이 비어 있으면 400을 반환한다", async () => {
      const res = await api.post("/api/auth/kakao").send({ accessToken: "" });
      expect(res.status).toBe(400);
    });
  });

  describe("구글", () => {
    it("처음 로그인하면 계정을 새로 만들고 토큰을 발급한다", async () => {
      mockGooglePayload({ sub: "google-sub-1", email: "g1@example.com", name: "구글유저" });

      const res = await api.post("/api/auth/google").send({ idToken: "valid-id-token" });

      expect(res.status).toBe(200);
      expect(res.body.user.email).toBe("g1@example.com");
      expect(res.body.user.nickname).toBe("구글유저");

      const user = await prisma.user.findUnique({ where: { email: "g1@example.com" } });
      expect(user?.provider).toBe("GOOGLE");
      expect(user?.providerId).toBe("google-sub-1");
    });

    it("같은 구글 계정으로 다시 로그인하면 새 계정을 만들지 않는다", async () => {
      mockGooglePayload({ sub: "google-sub-2", email: "g2@example.com", name: "구글유저2" });

      const first = await api.post("/api/auth/google").send({ idToken: "t1" });
      const second = await api.post("/api/auth/google").send({ idToken: "t2" });

      expect(first.body.user.id).toBe(second.body.user.id);
      expect(await prisma.user.count()).toBe(1);
    });

    it("ID 토큰 검증에 실패하면 401을 반환한다", async () => {
      verifyIdTokenMock.mockRejectedValue(new Error("invalid token"));

      const res = await api.post("/api/auth/google").send({ idToken: "bad-token" });
      expect(res.status).toBe(401);
    });

    it("payload가 없으면(빈 토큰) 401을 반환한다", async () => {
      mockGooglePayload(null);

      const res = await api.post("/api/auth/google").send({ idToken: "empty-payload-token" });
      expect(res.status).toBe(401);
    });

    it("이미 이메일/비밀번호로 가입된 이메일이면 409를 반환한다", async () => {
      await api
        .post("/api/auth/signup")
        .send({ email: "shared2@example.com", password: "password123", nickname: "로컬유저2" });

      mockGooglePayload({ sub: "google-sub-3", email: "shared2@example.com", name: "구글유저3" });

      const res = await api.post("/api/auth/google").send({ idToken: "t" });
      expect(res.status).toBe(409);
    });

    it("GOOGLE_CLIENT_ID가 설정되지 않았으면 503을 반환한다", async () => {
      const original = env.GOOGLE_CLIENT_ID;
      env.GOOGLE_CLIENT_ID = undefined;

      try {
        const res = await api.post("/api/auth/google").send({ idToken: "t" });
        expect(res.status).toBe(503);
      } finally {
        env.GOOGLE_CLIENT_ID = original;
      }
    });
  });
});
