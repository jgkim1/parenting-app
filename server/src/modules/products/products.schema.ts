import { z } from "zod";

export const listProductsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(50).default(20),
  categoryId: z.string().uuid().optional(),
  q: z.string().trim().min(1).max(100).optional(),
  // true여도 ADMIN이 아니면 컨트롤러에서 무시된다(비활성 상품은 관리자만 볼 수 있음).
  includeInactive: z.coerce.boolean().optional(),
});
export type ListProductsQuery = z.infer<typeof listProductsQuerySchema>;

export const createProductSchema = z.object({
  categoryId: z.string().uuid("올바른 카테고리가 아닙니다."),
  name: z.string().min(1, "상품명을 입력해주세요.").max(200),
  description: z.string().min(1, "상품 설명을 입력해주세요."),
  price: z.number().int().min(0, "가격은 0 이상이어야 합니다."),
  stock: z.number().int().min(0).default(0),
  imageUrls: z.array(z.string().url()).max(10).default([]),
});
export type CreateProductInput = z.infer<typeof createProductSchema>;

export const updateProductSchema = z.object({
  categoryId: z.string().uuid("올바른 카테고리가 아닙니다.").optional(),
  name: z.string().min(1, "상품명을 입력해주세요.").max(200).optional(),
  description: z.string().min(1, "상품 설명을 입력해주세요.").optional(),
  price: z.number().int().min(0, "가격은 0 이상이어야 합니다.").optional(),
  stock: z.number().int().min(0).optional(),
  imageUrls: z.array(z.string().url()).max(10).optional(),
  isActive: z.boolean().optional(),
});
export type UpdateProductInput = z.infer<typeof updateProductSchema>;

export const createReviewSchema = z.object({
  rating: z.number().int().min(1, "평점은 1~5 사이여야 합니다.").max(5, "평점은 1~5 사이여야 합니다."),
  content: z.string().min(1, "리뷰 내용을 입력해주세요.").max(1000),
});
export type CreateReviewInput = z.infer<typeof createReviewSchema>;

export const updateReviewSchema = createReviewSchema;
export type UpdateReviewInput = z.infer<typeof updateReviewSchema>;
