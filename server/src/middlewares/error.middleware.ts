import type { NextFunction, Request, Response } from "express";
import { MulterError } from "multer";
import { ZodError } from "zod";
import { AppError } from "../common/errors/AppError";

export function notFoundHandler(req: Request, res: Response) {
  res.status(404).json({ message: `경로를 찾을 수 없습니다: ${req.method} ${req.originalUrl}` });
}

// 항상 라우터 마운트 이후, 미들웨어 체인의 가장 마지막에 등록해야 한다.
export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      message: "요청 값이 유효하지 않습니다.",
      issues: err.flatten().fieldErrors,
    });
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ message: err.message });
  }

  if (err instanceof MulterError) {
    const message =
      err.code === "LIMIT_FILE_SIZE" ? "파일 크기는 5MB를 넘을 수 없습니다." : "파일 업로드에 실패했습니다.";
    return res.status(400).json({ message });
  }

  console.error(err);
  return res.status(500).json({ message: "서버 내부 오류가 발생했습니다." });
}
