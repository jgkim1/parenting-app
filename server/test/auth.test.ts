import { beforeEach, describe, expect, it } from "vitest";
import { api, authHeader, resetDatabase, signUpUser } from "./helpers";

describe("인증", () => {
  beforeEach(async () => {
    await resetDatabase();
  });

  describe("회원가입", () => {
    it("성공 시 토큰과 사용자 정보를 반환하고 비밀번호 해시는 노출하지 않는다", async () => {
      const res = await api
        .post("/api/auth/signup")
        .send({ email: "new@example.com", password: "password123", nickname: "새유저" });

      expect(res.status).toBe(201);
      expect(res.body.accessToken).toBeTruthy();
      expect(res.body.refreshToken).toBeTruthy();
      expect(res.body.user.email).toBe("new@example.com");
      expect(res.body.user.nickname).toBe("새유저");
      expect(res.body.user.role).toBe("CUSTOMER");
      expect(res.body.user.passwordHash).toBeUndefined();
    });

    it("이미 가입된 이메일이면 409를 반환한다", async () => {
      await signUpUser({ email: "dup@example.com" });

      const res = await api
        .post("/api/auth/signup")
        .send({ email: "dup@example.com", password: "password123", nickname: "다른닉네임" });

      expect(res.status).toBe(409);
    });

    it("비밀번호가 8자 미만이면 400을 반환한다", async () => {
      const res = await api
        .post("/api/auth/signup")
        .send({ email: "short@example.com", password: "1234567", nickname: "닉네임" });

      expect(res.status).toBe(400);
    });

    it("이메일 형식이 올바르지 않으면 400을 반환한다", async () => {
      const res = await api
        .post("/api/auth/signup")
        .send({ email: "not-an-email", password: "password123", nickname: "닉네임" });

      expect(res.status).toBe(400);
    });
  });

  describe("로그인", () => {
    it("올바른 자격증명이면 성공한다", async () => {
      const user = await signUpUser({ email: "login@example.com", password: "password123" });

      const res = await api
        .post("/api/auth/login")
        .send({ email: user.email, password: user.password });

      expect(res.status).toBe(200);
      expect(res.body.user.email).toBe(user.email);
    });

    it("비밀번호가 틀리면 401을 반환한다", async () => {
      const user = await signUpUser({ email: "wrongpw@example.com" });

      const res = await api
        .post("/api/auth/login")
        .send({ email: user.email, password: "wrong-password" });

      expect(res.status).toBe(401);
    });

    it("존재하지 않는 이메일도 비밀번호 오류와 동일한 메시지의 401을 반환한다", async () => {
      const wrongPassword = await api
        .post("/api/auth/login")
        .send({ email: "ghost@example.com", password: "password123" });

      const user = await signUpUser({ email: "exists@example.com" });
      const wrongCreds = await api
        .post("/api/auth/login")
        .send({ email: user.email, password: "wrong-password" });

      expect(wrongPassword.status).toBe(401);
      expect(wrongCreds.status).toBe(401);
      expect(wrongPassword.body.message).toBe(wrongCreds.body.message);
    });
  });

  describe("토큰 갱신/로그아웃", () => {
    it("refresh 토큰으로 새 토큰 쌍을 받고, 기존 refresh 토큰은 재사용할 수 없다", async () => {
      const user = await signUpUser();

      const refreshed = await api.post("/api/auth/refresh").send({ refreshToken: user.refreshToken });
      expect(refreshed.status).toBe(200);
      expect(refreshed.body.accessToken).toBeTruthy();
      expect(refreshed.body.refreshToken).not.toBe(user.refreshToken);

      const reused = await api.post("/api/auth/refresh").send({ refreshToken: user.refreshToken });
      expect(reused.status).toBe(401);
    });

    it("로그아웃하면 해당 refresh 토큰은 더 이상 갱신에 쓸 수 없다", async () => {
      const user = await signUpUser();

      const logoutRes = await api.post("/api/auth/logout").send({ refreshToken: user.refreshToken });
      expect(logoutRes.status).toBe(204);

      const refreshAfterLogout = await api
        .post("/api/auth/refresh")
        .send({ refreshToken: user.refreshToken });
      expect(refreshAfterLogout.status).toBe(401);
    });
  });

  describe("인증이 필요한 라우트 보호", () => {
    it("토큰 없이 /users/me를 호출하면 401을 반환한다", async () => {
      const res = await api.get("/api/users/me");
      expect(res.status).toBe(401);
    });

    it("유효한 토큰이면 본인 정보를 반환한다", async () => {
      const user = await signUpUser();
      const res = await api.get("/api/users/me").set(authHeader(user.accessToken));
      expect(res.status).toBe(200);
      expect(res.body.id).toBe(user.userId);
    });
  });
});
