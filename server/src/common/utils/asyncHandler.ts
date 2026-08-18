import type { NextFunction, Request, Response } from "express";

type AsyncRouteHandler = (req: Request, res: Response, next: NextFunction) => Promise<unknown>;

// Express 4는 async 핸들러에서 발생한 reject를 자동으로 잡아주지 않으므로,
// catch(next)로 감싸 error.middleware까지 전달되도록 한다.
export function asyncHandler(handler: AsyncRouteHandler) {
  return (req: Request, res: Response, next: NextFunction) => {
    handler(req, res, next).catch(next);
  };
}
