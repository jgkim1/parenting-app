import { prisma } from "../../config/prisma";
import { ForbiddenError, NotFoundError } from "../../common/errors/AppError";
import type { CreateChildInput, UpdateChildInput } from "./children.schema";

export async function listChildren(userId: string) {
  return prisma.child.findMany({
    where: { userId },
    orderBy: { birthDate: "desc" },
  });
}

export async function createChild(userId: string, input: CreateChildInput) {
  return prisma.child.create({
    data: {
      userId,
      nickname: input.nickname,
      gender: input.gender,
      birthDate: input.birthDate,
    },
  });
}

export async function updateChild(userId: string, childId: string, input: UpdateChildInput) {
  const child = await prisma.child.findUnique({ where: { id: childId } });
  if (!child) {
    throw new NotFoundError("자녀 정보를 찾을 수 없습니다.");
  }
  if (child.userId !== userId) {
    throw new ForbiddenError("본인 자녀 정보만 수정할 수 있습니다.");
  }

  return prisma.child.update({
    where: { id: childId },
    data: {
      nickname: input.nickname,
      gender: input.gender,
      birthDate: input.birthDate,
    },
  });
}

export async function deleteChild(userId: string, childId: string) {
  const child = await prisma.child.findUnique({ where: { id: childId } });
  if (!child) {
    throw new NotFoundError("자녀 정보를 찾을 수 없습니다.");
  }
  if (child.userId !== userId) {
    throw new ForbiddenError("본인 자녀 정보만 삭제할 수 있습니다.");
  }
  await prisma.child.delete({ where: { id: childId } });
}
