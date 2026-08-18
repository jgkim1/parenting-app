import type { Request, Response } from "express";
import { prisma } from "../../config/prisma";
import { NotFoundError } from "../../common/errors/AppError";

export async function getMeHandler(req: Request, res: Response) {
  const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
  if (!user) {
    throw new NotFoundError("사용자를 찾을 수 없습니다.");
  }

  const { passwordHash, ...safeUser } = user;
  res.status(200).json(safeUser);
}
