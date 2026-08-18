import { z } from "zod";

export const listArticlesQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(50).default(20),
  categoryId: z.string().uuid().optional(),
  // true여도 ADMIN이 아니면 컨트롤러에서 무시된다(비공개 아티클은 관리자만 볼 수 있음).
  includeInactive: z.coerce.boolean().optional(),
});
export type ListArticlesQuery = z.infer<typeof listArticlesQuerySchema>;

export const createArticleSchema = z.object({
  categoryId: z.string().uuid("올바른 카테고리가 아닙니다."),
  title: z.string().min(1, "제목을 입력해주세요.").max(200),
  content: z.string().min(1, "본문을 입력해주세요."),
  thumbnailUrl: z.string().url().optional(),
});
export type CreateArticleInput = z.infer<typeof createArticleSchema>;

export const updateArticleSchema = z.object({
  categoryId: z.string().uuid("올바른 카테고리가 아닙니다.").optional(),
  title: z.string().min(1, "제목을 입력해주세요.").max(200).optional(),
  content: z.string().min(1, "본문을 입력해주세요.").optional(),
  thumbnailUrl: z.string().url().nullable().optional(),
  isActive: z.boolean().optional(),
});
export type UpdateArticleInput = z.infer<typeof updateArticleSchema>;
