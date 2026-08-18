import type { Prisma } from "@prisma/client";
import { prisma } from "../../config/prisma";
import { NotFoundError } from "../../common/errors/AppError";
import type { CreateAdInput, ListAdsQuery, UpdateAdInput } from "./ads.schema";

// includeInactive는 관리자 광고 관리 화면에서만 true로 전달된다(컨트롤러에서 role 검증).
export async function listAds(query: ListAdsQuery, includeInactive = false) {
  const where: Prisma.AdWhereInput = {
    ...(includeInactive ? {} : { isActive: true }),
    ...(query.placement ? { placement: query.placement } : {}),
  };

  return prisma.ad.findMany({
    where,
    orderBy: [{ sortOrder: "asc" }, { createdAt: "desc" }],
  });
}

export async function createAd(input: CreateAdInput) {
  return prisma.ad.create({
    data: {
      placement: input.placement,
      title: input.title,
      imageUrl: input.imageUrl,
      linkUrl: input.linkUrl,
      sortOrder: input.sortOrder,
    },
  });
}

export async function updateAd(id: string, input: UpdateAdInput) {
  const ad = await prisma.ad.findUnique({ where: { id } });
  if (!ad) {
    throw new NotFoundError("광고를 찾을 수 없습니다.");
  }

  return prisma.ad.update({
    where: { id },
    data: {
      placement: input.placement,
      title: input.title,
      imageUrl: input.imageUrl,
      linkUrl: input.linkUrl,
      sortOrder: input.sortOrder,
      isActive: input.isActive,
    },
  });
}

// 광고는 다른 데이터가 참조하지 않아 하드 삭제한다.
export async function deleteAd(id: string) {
  const ad = await prisma.ad.findUnique({ where: { id } });
  if (!ad) {
    throw new NotFoundError("광고를 찾을 수 없습니다.");
  }
  await prisma.ad.delete({ where: { id } });
}
