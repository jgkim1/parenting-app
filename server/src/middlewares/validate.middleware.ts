import type { NextFunction, Request, Response } from "express";
import type { ZodSchema } from "zod";

// req.body를 zod 스키마로 검증/정제한다. 실패 시 ZodError를 next로 넘겨
// error.middleware가 일관된 400 응답으로 변환하도록 한다.
export function validateBody(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction) => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (err) {
      next(err);
    }
  };
}

// req.query를 zod 스키마로 검증/정제한다(페이지네이션 숫자 coercion 등).
export function validateQuery(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction) => {
    try {
      req.query = schema.parse(req.query);
      next();
    } catch (err) {
      next(err);
    }
  };
}
