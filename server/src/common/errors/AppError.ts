// 예상 가능한 도메인 에러를 표현하는 베이스 클래스. 컨트롤러/서비스에서 throw하면
// error.middleware가 statusCode와 message를 그대로 응답으로 변환한다.
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
  ) {
    super(message);
    this.name = "AppError";
  }
}

export class NotFoundError extends AppError {
  constructor(message = "리소스를 찾을 수 없습니다.") {
    super(404, message);
    this.name = "NotFoundError";
  }
}

export class BadRequestError extends AppError {
  constructor(message = "잘못된 요청입니다.") {
    super(400, message);
    this.name = "BadRequestError";
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = "인증이 필요합니다.") {
    super(401, message);
    this.name = "UnauthorizedError";
  }
}

export class ForbiddenError extends AppError {
  constructor(message = "권한이 없습니다.") {
    super(403, message);
    this.name = "ForbiddenError";
  }
}

export class ConflictError extends AppError {
  constructor(message = "이미 존재하는 데이터입니다.") {
    super(409, message);
    this.name = "ConflictError";
  }
}

export class ServiceUnavailableError extends AppError {
  constructor(message = "일시적으로 사용할 수 없는 기능입니다.") {
    super(503, message);
    this.name = "ServiceUnavailableError";
  }
}
