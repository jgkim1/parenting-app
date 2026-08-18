import { Router } from "express";
import { asyncHandler } from "../../common/utils/asyncHandler";
import { requireAuth } from "../../middlewares/auth.middleware";
import { getMeHandler } from "./users.controller";

// 자녀 프로필 CRUD 등 나머지 사용자 도메인 API는 이후 단계에서 이 라우터에 추가한다.
export const meRouter = Router();

meRouter.get("/me", requireAuth, asyncHandler(getMeHandler));
