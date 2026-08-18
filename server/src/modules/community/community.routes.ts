import { Router } from "express";
import { asyncHandler } from "../../common/utils/asyncHandler";
import { optionalAuth, requireAuth } from "../../middlewares/auth.middleware";
import { validateBody, validateQuery } from "../../middlewares/validate.middleware";
import {
  addCommentHandler,
  createPostHandler,
  deleteCommentHandler,
  deletePostHandler,
  getPostHandler,
  listPostsHandler,
  toggleLikeHandler,
  updatePostHandler,
} from "./community.controller";
import {
  createCommentSchema,
  createPostSchema,
  listPostsQuerySchema,
  updatePostSchema,
} from "./community.schema";

export const postsRouter = Router();
postsRouter.get("/", validateQuery(listPostsQuerySchema), asyncHandler(listPostsHandler));
postsRouter.get("/:id", optionalAuth, asyncHandler(getPostHandler));
postsRouter.post("/", requireAuth, validateBody(createPostSchema), asyncHandler(createPostHandler));
postsRouter.patch(
  "/:id",
  requireAuth,
  validateBody(updatePostSchema),
  asyncHandler(updatePostHandler),
);
postsRouter.delete("/:id", requireAuth, asyncHandler(deletePostHandler));
postsRouter.post(
  "/:id/comments",
  requireAuth,
  validateBody(createCommentSchema),
  asyncHandler(addCommentHandler),
);
postsRouter.post("/:id/like", requireAuth, asyncHandler(toggleLikeHandler));

export const commentsRouter = Router();
commentsRouter.delete("/:id", requireAuth, asyncHandler(deleteCommentHandler));
