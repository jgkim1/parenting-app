import { Router } from "express";
import { asyncHandler } from "../../common/utils/asyncHandler";
import { optionalAuth, requireAuth, requireRole } from "../../middlewares/auth.middleware";
import { validateBody, validateQuery } from "../../middlewares/validate.middleware";
import {
  createAdHandler,
  deleteAdHandler,
  listAdsHandler,
  updateAdHandler,
} from "./ads.controller";
import { createAdSchema, listAdsQuerySchema, updateAdSchema } from "./ads.schema";

export const adsRouter = Router();

adsRouter.get("/", optionalAuth, validateQuery(listAdsQuerySchema), asyncHandler(listAdsHandler));
adsRouter.post(
  "/",
  requireAuth,
  requireRole("ADMIN"),
  validateBody(createAdSchema),
  asyncHandler(createAdHandler),
);
adsRouter.patch(
  "/:id",
  requireAuth,
  requireRole("ADMIN"),
  validateBody(updateAdSchema),
  asyncHandler(updateAdHandler),
);
adsRouter.delete("/:id", requireAuth, requireRole("ADMIN"), asyncHandler(deleteAdHandler));
