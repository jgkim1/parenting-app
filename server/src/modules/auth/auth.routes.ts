import { Router } from "express";
import { asyncHandler } from "../../common/utils/asyncHandler";
import { validateBody } from "../../middlewares/validate.middleware";
import {
  googleLoginHandler,
  kakaoLoginHandler,
  loginHandler,
  logoutHandler,
  refreshHandler,
  signupHandler,
} from "./auth.controller";
import {
  googleLoginSchema,
  kakaoLoginSchema,
  loginSchema,
  refreshSchema,
  signupSchema,
} from "./auth.schema";

export const authRouter = Router();

authRouter.post("/signup", validateBody(signupSchema), asyncHandler(signupHandler));
authRouter.post("/login", validateBody(loginSchema), asyncHandler(loginHandler));
authRouter.post("/refresh", validateBody(refreshSchema), asyncHandler(refreshHandler));
authRouter.post("/logout", validateBody(refreshSchema), asyncHandler(logoutHandler));
authRouter.post("/kakao", validateBody(kakaoLoginSchema), asyncHandler(kakaoLoginHandler));
authRouter.post("/google", validateBody(googleLoginSchema), asyncHandler(googleLoginHandler));
