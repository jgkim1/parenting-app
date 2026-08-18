import { Router } from "express";
import { asyncHandler } from "../../common/utils/asyncHandler";
import { requireAuth } from "../../middlewares/auth.middleware";
import { validateBody } from "../../middlewares/validate.middleware";
import {
  createChildHandler,
  deleteChildHandler,
  listChildrenHandler,
  updateChildHandler,
} from "./children.controller";
import { createChildSchema, updateChildSchema } from "./children.schema";

export const childrenRouter = Router();

childrenRouter.use(requireAuth);
childrenRouter.get("/", asyncHandler(listChildrenHandler));
childrenRouter.post("/", validateBody(createChildSchema), asyncHandler(createChildHandler));
childrenRouter.patch("/:id", validateBody(updateChildSchema), asyncHandler(updateChildHandler));
childrenRouter.delete("/:id", asyncHandler(deleteChildHandler));
