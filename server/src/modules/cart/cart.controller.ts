import type { Request, Response } from "express";
import * as cartService from "./cart.service";
import type { AddCartItemInput, UpdateCartItemInput } from "./cart.schema";

export async function getCartHandler(req: Request, res: Response) {
  const cart = await cartService.getCart(req.user!.id);
  res.status(200).json(cart);
}

export async function addItemHandler(req: Request, res: Response) {
  const cart = await cartService.addItem(req.user!.id, req.body as AddCartItemInput);
  res.status(200).json(cart);
}

export async function updateItemHandler(req: Request, res: Response) {
  const cart = await cartService.updateItem(
    req.user!.id,
    req.params.productId,
    req.body as UpdateCartItemInput,
  );
  res.status(200).json(cart);
}

export async function removeItemHandler(req: Request, res: Response) {
  const cart = await cartService.removeItem(req.user!.id, req.params.productId);
  res.status(200).json(cart);
}
