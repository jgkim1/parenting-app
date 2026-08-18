import { randomUUID } from "node:crypto";
import jwt from "jsonwebtoken";
import type { UserRole } from "@prisma/client";
import { env } from "../../config/env";

export interface AccessTokenPayload {
  sub: string;
  role: UserRole;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN,
  } as jwt.SignOptions);
}

// jti(토큰 고유 id)를 매번 랜덤으로 넣는다. jwt.sign은 같은 payload+같은 초에 서명하면
// 바이트 단위로 동일한 문자열을 만들어내는데, 리프레시 토큰은 문자열 해시로 재사용
// 여부를 판별하므로(auth.service.ts) 동일 문자열이 나오면 회전된 새 토큰과 폐기된
// 이전 토큰이 같은 해시를 갖게 되어 재사용 탐지가 무력화된다.
export function signRefreshToken(payload: AccessTokenPayload): string {
  return jwt.sign({ ...payload, jti: randomUUID() }, env.JWT_REFRESH_SECRET, {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN,
  } as jwt.SignOptions);
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  return jwt.verify(token, env.JWT_ACCESS_SECRET) as AccessTokenPayload;
}

export function verifyRefreshToken(token: string): AccessTokenPayload {
  return jwt.verify(token, env.JWT_REFRESH_SECRET) as AccessTokenPayload;
}

// jsonwebtoken은 만료 시각을 토큰 내부(exp)에만 담으므로, DB에 별도 저장하기 위해
// 디코딩해서 Date로 변환한다.
export function getTokenExpiry(token: string): Date {
  const decoded = jwt.decode(token) as { exp?: number } | null;
  if (!decoded?.exp) {
    throw new Error("토큰에 만료 정보(exp)가 없습니다.");
  }
  return new Date(decoded.exp * 1000);
}
