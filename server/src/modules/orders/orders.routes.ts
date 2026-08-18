import { Router } from "express";
import { asyncHandler } from "../../common/utils/asyncHandler";
import { requireAuth } from "../../middlewares/auth.middleware";
import { validateBody, validateQuery } from "../../middlewares/validate.middleware";
import { createOrderHandler, getOrderHandler, listOrdersHandler } from "./orders.controller";
import { createOrderSchema, listOrdersQuerySchema } from "./orders.schema";

export const ordersRouter = Router();

ordersRouter.use(requireAuth);
ordersRouter.get("/", validateQuery(listOrdersQuerySchema), asyncHandler(listOrdersHandler));
ordersRouter.get("/:id", asyncHandler(getOrderHandler));
ordersRouter.post("/", validateBody(createOrderSchema), asyncHandler(createOrderHandler));
