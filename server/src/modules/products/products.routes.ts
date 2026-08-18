import { Router } from "express";
import { asyncHandler } from "../../common/utils/asyncHandler";
import { optionalAuth, requireAuth, requireRole } from "../../middlewares/auth.middleware";
import { validateBody, validateQuery } from "../../middlewares/validate.middleware";
import {
  createProductHandler,
  createReviewHandler,
  deleteReviewHandler,
  getProductHandler,
  listCategoriesHandler,
  listProductsHandler,
  updateProductHandler,
  updateReviewHandler,
} from "./products.controller";
import {
  createProductSchema,
  createReviewSchema,
  listProductsQuerySchema,
  updateProductSchema,
  updateReviewSchema,
} from "./products.schema";

export const categoriesRouter = Router();
categoriesRouter.get("/", asyncHandler(listCategoriesHandler));

export const productsRouter = Router();
productsRouter.get(
  "/",
  optionalAuth,
  validateQuery(listProductsQuerySchema),
  asyncHandler(listProductsHandler),
);
productsRouter.get("/:id", optionalAuth, asyncHandler(getProductHandler));
productsRouter.post(
  "/",
  requireAuth,
  requireRole("SELLER", "ADMIN"),
  validateBody(createProductSchema),
  asyncHandler(createProductHandler),
);
productsRouter.patch(
  "/:id",
  requireAuth,
  requireRole("SELLER", "ADMIN"),
  validateBody(updateProductSchema),
  asyncHandler(updateProductHandler),
);
productsRouter.post(
  "/:id/reviews",
  requireAuth,
  validateBody(createReviewSchema),
  asyncHandler(createReviewHandler),
);

export const reviewsRouter = Router();
reviewsRouter.patch(
  "/:id",
  requireAuth,
  validateBody(updateReviewSchema),
  asyncHandler(updateReviewHandler),
);
reviewsRouter.delete("/:id", requireAuth, asyncHandler(deleteReviewHandler));
