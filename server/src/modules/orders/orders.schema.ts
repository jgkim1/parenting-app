import { z } from "zod";

export const createOrderSchema = z.object({
  shippingAddr: z.string().min(1, "배송지를 입력해주세요.").max(300),
});
export type CreateOrderInput = z.infer<typeof createOrderSchema>;

export const listOrdersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(50).default(20),
});
export type ListOrdersQuery = z.infer<typeof listOrdersQuerySchema>;
