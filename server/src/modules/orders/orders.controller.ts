import type { Request, Response } from "express";
import * as ordersService from "./orders.service";
import type { CreateOrderInput, ListOrdersQuery } from "./orders.schema";

export async function createOrderHandler(req: Request, res: Response) {
  const order = await ordersService.createOrder(req.user!.id, req.body as CreateOrderInput);
  res.status(201).json(order);
}

export async function listOrdersHandler(req: Request, res: Response) {
  const result = await ordersService.listOrders(
    req.user!.id,
    req.query as unknown as ListOrdersQuery,
  );
  res.status(200).json(result);
}

export async function getOrderHandler(req: Request, res: Response) {
  const order = await ordersService.getOrderById(req.user!.id, req.params.id);
  res.status(200).json(order);
}
