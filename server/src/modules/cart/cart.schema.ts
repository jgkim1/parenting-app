import { z } from "zod";

export const addCartItemSchema = z.object({
  productId: z.string().uuid("올바른 상품이 아닙니다."),
  quantity: z.number().int().min(1, "수량은 1 이상이어야 합니다.").default(1),
});
export type AddCartItemInput = z.infer<typeof addCartItemSchema>;

export const updateCartItemSchema = z.object({
  quantity: z.number().int().min(1, "수량은 1 이상이어야 합니다."),
});
export type UpdateCartItemInput = z.infer<typeof updateCartItemSchema>;
