import { Router } from "express";
import { asyncHandler } from "../../common/utils/asyncHandler";
import { optionalAuth, requireAuth, requireRole } from "../../middlewares/auth.middleware";
import { validateBody, validateQuery } from "../../middlewares/validate.middleware";
import {
  createArticleHandler,
  deleteArticleHandler,
  getArticleHandler,
  listArticleCategoriesHandler,
  listArticlesHandler,
  updateArticleHandler,
} from "./articles.controller";
import {
  createArticleSchema,
  listArticlesQuerySchema,
  updateArticleSchema,
} from "./articles.schema";

export const articleCategoriesRouter = Router();
articleCategoriesRouter.get("/", asyncHandler(listArticleCategoriesHandler));

export const articlesRouter = Router();
articlesRouter.get(
  "/",
  optionalAuth,
  validateQuery(listArticlesQuerySchema),
  asyncHandler(listArticlesHandler),
);
articlesRouter.get("/:id", optionalAuth, asyncHandler(getArticleHandler));
articlesRouter.post(
  "/",
  requireAuth,
  requireRole("ADMIN"),
  validateBody(createArticleSchema),
  asyncHandler(createArticleHandler),
);
articlesRouter.patch(
  "/:id",
  requireAuth,
  requireRole("ADMIN"),
  validateBody(updateArticleSchema),
  asyncHandler(updateArticleHandler),
);
articlesRouter.delete("/:id", requireAuth, requireRole("ADMIN"), asyncHandler(deleteArticleHandler));
