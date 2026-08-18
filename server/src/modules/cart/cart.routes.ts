import { Router } from "express";
import { asyncHandler } from "../../common/utils/asyncHandler";
import { requireAuth } from "../../middlewares/auth.middleware";
import { validateBody } from "../../middlewares/validate.middleware";
import {
  addItemHandler,
  getCartHandler,
  removeItemHandler,
  updateItemHandler,
} from "./cart.controller";
import { addCartItemSchema, updateCartItemSchema } from "./cart.schema";

export const cartRouter = Router();

cartRouter.use(requireAuth);
cartRouter.get("/", asyncHandler(getCartHandler));
cartRouter.post("/items", validateBody(addCartItemSchema), asyncHandler(addItemHandler));
cartRouter.patch(
  "/items/:productId",
  validateBody(updateCartItemSchema),
  asyncHandler(updateItemHandler),
);
cartRouter.delete("/items/:productId", asyncHandler(removeItemHandler));
