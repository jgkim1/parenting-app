import { z } from "zod";

// 앱 쪽 AdBanner 삽입 지점과 1:1로 대응하는 Prisma AdPlacement enum과 동일한 값이어야 한다.
export const AD_PLACEMENTS = [
  "TODAY",
  "PRODUCT_LIST",
  "ARTICLE_LIST",
  "COMMUNITY_LIST",
  "PRODUCT_DETAIL",
  "POST_DETAIL",
] as const;

export const listAdsQuerySchema = z.object({
  placement: z.enum(AD_PLACEMENTS).optional(),
  // true여도 ADMIN이 아니면 컨트롤러에서 무시된다(비활성 광고는 관리자만 볼 수 있음).
  includeInactive: z.coerce.boolean().optional(),
});
export type ListAdsQuery = z.infer<typeof listAdsQuerySchema>;

export const createAdSchema = z.object({
  placement: z.enum(AD_PLACEMENTS, { message: "올바른 삽입 위치가 아닙니다." }),
  title: z.string().min(1, "광고 제목을 입력해주세요.").max(100),
  imageUrl: z.string().url("올바른 이미지 URL이 아닙니다."),
  linkUrl: z.string().url("올바른 링크 URL이 아닙니다.").optional(),
  sortOrder: z.number().int().default(0),
});
export type CreateAdInput = z.infer<typeof createAdSchema>;

export const updateAdSchema = z.object({
  placement: z.enum(AD_PLACEMENTS, { message: "올바른 삽입 위치가 아닙니다." }).optional(),
  title: z.string().min(1, "광고 제목을 입력해주세요.").max(100).optional(),
  imageUrl: z.string().url("올바른 이미지 URL이 아닙니다.").optional(),
  linkUrl: z.string().url("올바른 링크 URL이 아닙니다.").nullable().optional(),
  sortOrder: z.number().int().optional(),
  isActive: z.boolean().optional(),
});
export type UpdateAdInput = z.infer<typeof updateAdSchema>;
