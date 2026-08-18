import type { NextFunction, Request, Response } from "express";
import type { UserRole } from "@prisma/client";
import { ForbiddenError, UnauthorizedError } from "../common/errors/AppError";
import { verifyAccessToken } from "../common/utils/jwt";

// Authorization: Bearer <accessToken> 헤더를 검증하여 req.user를 채운다.
// 이후 보호된 라우트는 이 미들웨어를 거친 뒤에만 마운트한다.
export function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    throw new UnauthorizedError("액세스 토큰이 필요합니다.");
  }

  const token = header.slice("Bearer ".length);

  try {
    const payload = verifyAccessToken(token);
    req.user = { id: payload.sub, role: payload.role };
    next();
  } catch {
    throw new UnauthorizedError("액세스 토큰이 유효하지 않거나 만료되었습니다.");
  }
}

// 로그인 여부에 따라 응답이 달라지는(예: 좋아요 여부 표시) 공개 라우트에서 사용한다.
// 토큰이 없거나 유효하지 않아도 막지 않고 비로그인 상태로 통과시킨다.
export function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (header?.startsWith("Bearer ")) {
    try {
      const payload = verifyAccessToken(header.slice("Bearer ".length));
      req.user = { id: payload.sub, role: payload.role };
    } catch {
      // 무효한 토큰은 무시하고 비로그인 상태로 취급한다.
    }
  }
  next();
}

// requireAuth 이후에 마운트하여 특정 역할(SELLER, ADMIN 등)만 접근을 허용한다.
export function requireRole(...roles: UserRole[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) {
      throw new ForbiddenError("이 작업을 수행할 권한이 없습니다.");
    }
    next();
  };
}
