import { z } from "zod";

export const listPostsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(50).default(20),
  category: z.string().trim().min(1).max(50).optional(),
  q: z.string().trim().min(1).max(100).optional(),
});
export type ListPostsQuery = z.infer<typeof listPostsQuerySchema>;

export const createPostSchema = z.object({
  title: z.string().min(1, "제목을 입력해주세요.").max(200),
  content: z.string().min(1, "내용을 입력해주세요."),
  category: z.string().trim().min(1).max(50).optional(),
  imageUrl: z.string().url().optional(),
});
export type CreatePostInput = z.infer<typeof createPostSchema>;

export const updatePostSchema = z.object({
  title: z.string().min(1, "제목을 입력해주세요.").max(200),
  content: z.string().min(1, "내용을 입력해주세요."),
  category: z.string().trim().min(1).max(50).optional(),
  imageUrl: z.string().url().optional(),
});
export type UpdatePostInput = z.infer<typeof updatePostSchema>;

export const createCommentSchema = z.object({
  content: z.string().min(1, "댓글 내용을 입력해주세요.").max(1000),
});
export type CreateCommentInput = z.infer<typeof createCommentSchema>;
